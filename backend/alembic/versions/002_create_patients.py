"""create patients and caretaker_patient tables"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'patients',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('patient_unique_id', sa.String(20), unique=True, nullable=False), # ALZ-XX-XXXX
        sa.Column('full_name', sa.String(255), nullable=False),
        sa.Column('dob', sa.Date(), nullable=False),
        sa.Column('level', sa.Integer(), nullable=False), # 1/2/3
        sa.Column('language', sa.String(50), nullable=True),
        sa.Column('trusted_phone', sa.String(50), nullable=True),
        sa.Column('doctor_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True)
    )

    op.create_table(
        'caretaker_patient',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('caretaker_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('patient_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('patients.id'), nullable=False),
        sa.Column('relationship', sa.String(100), nullable=True),
        sa.Column('is_primary', sa.Boolean(), server_default=sa.text('false'), nullable=True),
        sa.Column('escalation_order', sa.Integer(), nullable=True),
        sa.Column('linked_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True)
    )

def downgrade():
    op.drop_table('caretaker_patient')
    op.drop_table('patients')
