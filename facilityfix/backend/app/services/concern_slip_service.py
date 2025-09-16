from typing import List, Optional
from datetime import datetime
from app.models.database_models import ConcernSlip, Notification
from app.database.database_service import DatabaseService, database_service
from app.database.collections import COLLECTIONS
import uuid

class ConcernSlipService:
    def __init__(self):
        self.db = DatabaseService()

    async def create_concern_slip(self, reported_by: str, concern_data: dict) -> ConcernSlip:
        """Create a new concern slip - the entry point for repair/maintenance issues"""

        # Fetch reporter profile from Firestore
        success, user_profile, error = await database_service.get_document(
            COLLECTIONS['users'], reported_by
        )
        if not success or not user_profile:
            raise ValueError("Reporter profile not found")

        if user_profile.get("role") != "tenant":
            raise ValueError("Only tenants can submit concern slips")

        concern_slip_data = {
            "id": str(uuid.uuid4()),
            "reported_by": reported_by,
            "title": concern_data["title"],
            "description": concern_data["description"],
            "location": concern_data["location"],
            "category": concern_data["category"],
            "priority": concern_data.get("priority", "medium"),
            "unit_id": concern_data.get("unit_id"),
            "attachments": concern_data.get("attachments", []),
            "status": "pending",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }

        # Create concern slip
        await self.db.create_document("concern_slips", concern_slip_data["id"], concern_slip_data)

        # Send notification to all admins
        await self._send_admin_notification(
            concern_slip_data["id"],
            f"New concern slip submitted: {concern_slip_data['title']}"
        )

        return ConcernSlip(**concern_slip_data)

    async def evaluate_concern_slip(self, concern_slip_id: str, evaluated_by: str, evaluation_data: dict) -> ConcernSlip:
        """Evaluate concern slip - approve/reject and determine resolution type"""

        # Verify evaluator is admin
        success, evaluator_profile, error = await database_service.get_document(
            COLLECTIONS['users'], evaluated_by
        )
        if not success or not evaluator_profile or evaluator_profile.get("role") != "admin":
            raise ValueError("Only admins can evaluate concern slips")

        # Verify concern slip exists and is pending
        concern_slip = await self.db.get_document("concern_slips", concern_slip_id)
        if not concern_slip:
            raise ValueError("Concern slip not found")

        if concern_slip.get("status") != "pending":
            raise ValueError("Only pending concern slips can be evaluated")

        update_data = {
            "status": evaluation_data["status"],
            "evaluated_by": evaluated_by,
            "evaluated_at": datetime.utcnow(),
            "urgency_assessment": evaluation_data.get("urgency_assessment"),
            "admin_notes": evaluation_data.get("admin_notes"),
            "updated_at": datetime.utcnow()
        }

        # Set resolution type if approved
        if evaluation_data["status"] == "approved":
            update_data["resolution_type"] = evaluation_data.get("resolution_type")

        await self.db.update_document("concern_slips", concern_slip_id, update_data)

        # Send notification to tenant
        tenant_id = concern_slip.get("reported_by")
        status_message = "approved" if evaluation_data["status"] == "approved" else "rejected"
        await self._send_tenant_notification(
            tenant_id,
            concern_slip_id,
            f"Your concern slip has been {status_message}"
        )

        updated_concern = await self.db.get_document("concern_slips", concern_slip_id)
        return ConcernSlip(**updated_concern)

    async def get_concern_slip(self, concern_slip_id: str) -> Optional[ConcernSlip]:
        """Get concern slip by ID"""
        concern_data = await self.db.get_document("concern_slips", concern_slip_id)
        return ConcernSlip(**concern_data) if concern_data else None

    async def get_concern_slips_by_tenant(self, tenant_id: str) -> List[ConcernSlip]:
        """Get all concern slips submitted by a tenant"""
        concerns = await self.db.query_documents("concern_slips", {"reported_by": tenant_id})
        return [ConcernSlip(**concern) for concern in concerns]

    async def get_concern_slips_by_status(self, status: str) -> List[ConcernSlip]:
        """Get all concern slips with specific status"""
        concerns = await self.db.query_documents("concern_slips", {"status": status})
        return [ConcernSlip(**concern) for concern in concerns]

    async def get_pending_concern_slips(self) -> List[ConcernSlip]:
        """Get all pending concern slips awaiting evaluation"""
        concerns = await self.db.query_documents("concern_slips", {"status": "pending"})
        return [ConcernSlip(**concern) for concern in concerns]

    async def get_approved_concern_slips(self) -> List[ConcernSlip]:
        """Get all approved concern slips ready for resolution"""
        concerns = await self.db.query_documents("concern_slips", {"status": "approved"})
        return [ConcernSlip(**concern) for concern in concerns]

    async def get_all_concern_slips(self) -> List[ConcernSlip]:
        """Get all concern slips (Admin only)"""
        concerns = await self.db.get_all_documents("concern_slips")
        return [ConcernSlip(**concern) for concern in concerns]

    async def _send_admin_notification(self, concern_slip_id: str, message: str):
        """Send notification to all admins"""
        # Get all admin users
        admin_users = await self.db.query_documents("user_profiles", {"role": "admin"})

        for admin in admin_users:
            notification_data = {
                "id": str(uuid.uuid4()),
                "recipient_id": admin.get("id"),
                "title": "New Concern Slip",
                "message": message,
                "notification_type": "concern_submitted",
                "related_id": concern_slip_id,
                "is_read": False,
                "created_at": datetime.utcnow()
            }
            await self.db.create_document("notifications", notification_data["id"], notification_data)

    async def _send_tenant_notification(self, recipient_id: str, concern_slip_id: str, message: str):
        """Send notification to tenant about concern slip updates"""
        notification_data = {
            "id": str(uuid.uuid4()),
            "recipient_id": recipient_id,
            "title": "Concern Slip Update",
            "message": message,
            "notification_type": "concern_update",
            "related_id": concern_slip_id,
            "is_read": False,
            "created_at": datetime.utcnow()
        }
        await self.db.create_document("notifications", notification_data["id"], notification_data)
