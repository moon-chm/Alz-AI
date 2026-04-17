"""create medications table"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'medications',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('patient_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('patients.id'), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('dosage', sa.String(100), nullable=False),
        sa.Column('scheduled_times', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('tablet_photo_url', sa.String(500), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default=sa.text('true'), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False)
    )

def downgrade():
    op.drop_table('medications')
