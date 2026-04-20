"""production governance

Revision ID: 007
Revises: 006
Create Date: 2026-04-18

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '007'
down_revision = '006'
branch_labels = None
depends_on = None

def upgrade():
    # 1. Add under_dispute to users table
    op.add_column('users', sa.Column('under_dispute', sa.Boolean(), server_default=sa.text('false'), nullable=False))
    
    # 2. Add link_status to caretaker_patient table
    op.add_column('caretaker_patient', sa.Column('link_status', sa.String(length=50), server_default='active', nullable=False))
    
    # 3. Create index on nmc_number for faster conflict lookups
    op.create_index('idx_user_nmc', 'users', ['nmc_number'], unique=False)

def downgrade():
    # 1. Drop index
    op.drop_index('idx_user_nmc', table_name='users')
    
    # 2. Drop link_status from caretaker_patient
    op.drop_column('caretaker_patient', 'link_status')
    
    # 3. Drop under_dispute from users
    op.drop_column('users', 'under_dispute')
