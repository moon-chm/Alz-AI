"""create alerts table"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'alerts',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('patient_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('patients.id'), nullable=False),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('alert_type', sa.String(100), nullable=False),
        sa.Column('severity', sa.Integer(), nullable=False), # 1-5
        sa.Column('message', sa.Text(), nullable=False),
        sa.Column('is_acknowledged', sa.Boolean(), server_default=sa.text('false'), nullable=True),
        sa.Column('acknowledged_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('acknowledged_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True)
    )

def downgrade():
    op.drop_table('alerts')
