"""create users table"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(255), unique=True, nullable=False),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('role', sa.Enum('doctor', 'caretaker', name='user_role_enum'), nullable=False),
        sa.Column('full_name', sa.String(255), nullable=False),
        sa.Column('phone', sa.String(50), nullable=False),
        sa.Column('nmc_number', sa.String(100), nullable=True),
        sa.Column('is_verified', sa.Boolean(), server_default=sa.text('false'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True)
    )

def downgrade():
    op.drop_table('users')
    op.execute('DROP TYPE user_role_enum;')
