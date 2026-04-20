"""add updated_at to users

Revision ID: 009
Revises: 008
Create Date: 2026-04-18

"""
from alembic import op
import sqlalchemy as sa
from datetime import datetime

# revision identifiers, used by Alembic.
revision = '009'
down_revision = '008'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('updated_at', sa.DateTime(), nullable=True))
    # Fill existing rows with current time
    op.execute("UPDATE users SET updated_at = NOW()")
    # Make it non-nullable if desired, but here we'll keep it nullable or set it as NOT NULL later
    op.alter_column('users', 'updated_at', nullable=False)

def downgrade():
    op.drop_column('users', 'updated_at')
