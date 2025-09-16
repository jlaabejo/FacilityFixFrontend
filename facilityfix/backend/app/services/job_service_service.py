from typing import List, Optional
from datetime import datetime
from app.models.database_models import JobService, UserProfile, ConcernSlip, Notification
from app.database.database_service import DatabaseService
from app.services.user_id_service import UserIdService
import uuid

class JobServiceService:
    def __init__(self):
        self.db = DatabaseService()
        self.user_service = UserIdService()

    async def create_job_service(self, concern_slip_id: str, created_by: str, job_data: dict) -> JobService:
        """Create a new job service from an approved concern slip"""
        
        # Verify concern slip exists and is approved
        concern_slip = await self.db.get_document("concern_slips", concern_slip_id)
        if not concern_slip:
            raise ValueError("Concern slip not found")
        
        if concern_slip.get("status") != "approved":
            raise ValueError("Concern slip must be approved before creating job service")
        
        # Verify creator is admin
        creator_profile = await self.user_service.get_user_profile(created_by)
        if not creator_profile or creator_profile.role != "admin":
            raise ValueError("Only admins can create job services")

        job_service_data = {
            "id": str(uuid.uuid4()),
            "concern_slip_id": concern_slip_id,
            "created_by": created_by,
            "title": job_data.get("title") or concern_slip.get("title"),
            "description": job_data.get("description") or concern_slip.get("description"),
            "location": job_data.get("location") or concern_slip.get("location"),
            "category": job_data.get("category") or concern_slip.get("category"),
            "priority": job_data.get("priority") or concern_slip.get("priority"),
            "status": "assigned",
            "assigned_to": job_data.get("assigned_to"),
            "scheduled_date": job_data.get("scheduled_date"),
            "estimated_hours": job_data.get("estimated_hours"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }

        # Create job service
        await self.db.create_document("job_services", job_service_data["id"], job_service_data)
        
        # Update concern slip status
        await self.db.update_document("concern_slips", concern_slip_id, {
            "resolution_type": "job_service",
            "updated_at": datetime.utcnow()
        })

        # Send notification to assigned staff
        if job_service_data.get("assigned_to"):
            await self._send_assignment_notification(
                job_service_data["assigned_to"], 
                job_service_data["id"],
                job_service_data["title"]
            )

        # Send notification to tenant
        await self._send_tenant_notification(
            concern_slip.get("reported_by"),
            job_service_data["id"],
            "Your concern has been assigned to our internal staff"
        )

        return JobService(**job_service_data)

    async def assign_job_service(self, job_service_id: str, assigned_to: str, assigned_by: str) -> JobService:
        """Assign job service to internal staff member"""
        
        # Verify assigner is admin
        assigner_profile = await self.user_service.get_user_profile(assigned_by)
        if not assigner_profile or assigner_profile.role != "admin":
            raise ValueError("Only admins can assign job services")

        # Verify assignee is staff
        assignee_profile = await self.user_service.get_user_profile(assigned_to)
        if not assignee_profile or assignee_profile.role != "staff":
            raise ValueError("Job services can only be assigned to staff members")

        # Update job service
        update_data = {
            "assigned_to": assigned_to,
            "status": "assigned",
            "updated_at": datetime.utcnow()
        }

        await self.db.update_document("job_services", job_service_id, update_data)
        
        # Send notification to assigned staff
        job_service = await self.db.get_document("job_services", job_service_id)
        await self._send_assignment_notification(
            assigned_to, 
            job_service_id,
            job_service.get("title", "Job Service Assignment")
        )

        updated_job = await self.db.get_document("job_services", job_service_id)
        return JobService(**updated_job)

    async def update_job_status(self, job_service_id: str, status: str, updated_by: str, notes: Optional[str] = None) -> JobService:
        """Update job service status"""
        
        valid_statuses = ["assigned", "in_progress", "completed", "closed"]
        if status not in valid_statuses:
            raise ValueError(f"Invalid status. Must be one of: {valid_statuses}")

        update_data = {
            "status": status,
            "updated_at": datetime.utcnow()
        }

        # Add timestamp for specific status changes
        if status == "in_progress":
            update_data["started_at"] = datetime.utcnow()
        elif status == "completed":
            update_data["completed_at"] = datetime.utcnow()

        # Add notes if provided
        if notes:
            if status == "completed":
                update_data["completion_notes"] = notes
            else:
                update_data["staff_notes"] = notes

        await self.db.update_document("job_services", job_service_id, update_data)

        # Send notifications based on status
        job_service = await self.db.get_document("job_services", job_service_id)
        concern_slip = await self.db.get_document("concern_slips", job_service.get("concern_slip_id"))
        
        if status == "completed":
            # Notify tenant of completion
            await self._send_tenant_notification(
                concern_slip.get("reported_by"),
                job_service_id,
                f"Your repair request has been completed: {job_service.get('title')}"
            )

        updated_job = await self.db.get_document("job_services", job_service_id)
        return JobService(**updated_job)

    async def add_work_notes(self, job_service_id: str, notes: str, added_by: str) -> JobService:
        """Add work notes to job service"""
        
        job_service = await self.db.get_document("job_services", job_service_id)
        if not job_service:
            raise ValueError("Job service not found")

        current_notes = job_service.get("staff_notes", "")
        timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M")
        user_profile = await self.user_service.get_user_profile(added_by)
        user_name = f"{user_profile.first_name} {user_profile.last_name}" if user_profile else "Unknown"
        
        new_note = f"\n[{timestamp}] {user_name}: {notes}"
        updated_notes = current_notes + new_note

        await self.db.update_document("job_services", job_service_id, {
            "staff_notes": updated_notes,
            "updated_at": datetime.utcnow()
        })

        updated_job = await self.db.get_document("job_services", job_service_id)
        return JobService(**updated_job)

    async def get_job_service(self, job_service_id: str) -> Optional[JobService]:
        """Get job service by ID"""
        job_data = await self.db.get_document("job_services", job_service_id)
        return JobService(**job_data) if job_data else None

    async def get_job_services_by_staff(self, staff_id: str) -> List[JobService]:
        """Get all job services assigned to a staff member"""
        jobs = await self.db.query_documents("job_services", {"assigned_to": staff_id})
        return [JobService(**job) for job in jobs]

    async def get_job_services_by_status(self, status: str) -> List[JobService]:
        """Get all job services with specific status"""
        jobs = await self.db.query_documents("job_services", {"status": status})
        return [JobService(**job) for job in jobs]

    async def get_all_job_services(self) -> List[JobService]:
        """Get all job services (admin only)"""
        jobs = await self.db.get_all_documents("job_services")
        return [JobService(**job) for job in jobs]

    async def _send_assignment_notification(self, recipient_id: str, job_service_id: str, title: str):
        """Send notification when job is assigned"""
        notification_data = {
            "id": str(uuid.uuid4()),
            "recipient_id": recipient_id,
            "title": "New Job Assignment",
            "message": f"You have been assigned a new job: {title}",
            "notification_type": "job_assigned",
            "related_id": job_service_id,
            "is_read": False,
            "created_at": datetime.utcnow()
        }
        await self.db.create_document("notifications", notification_data["id"], notification_data)

    async def _send_tenant_notification(self, recipient_id: str, job_service_id: str, message: str):
        """Send notification to tenant about job service updates"""
        notification_data = {
            "id": str(uuid.uuid4()),
            "recipient_id": recipient_id,
            "title": "Job Service Update",
            "message": message,
            "notification_type": "job_update",
            "related_id": job_service_id,
            "is_read": False,
            "created_at": datetime.utcnow()
        }
        await self.db.create_document("notifications", notification_data["id"], notification_data)
