"""create appointments table"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'appointments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('patient_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('patients.id'), nullable=False),
        sa.Column('doctor_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('caretaker_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('scheduled_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('status', sa.Enum('pending', 'confirmed', 'completed', 'cancelled', name='appointment_status_enum'), server_default='pending', nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('reminder_sent', sa.Boolean(), server_default=sa.text('false'), nullable=True)
    )

def downgrade():
    op.drop_table('appointments')
    op.execute('DROP TYPE appointment_status_enum;')
