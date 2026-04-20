"""add last_login to users

Revision ID: 008
Revises: 007
Create Date: 2026-04-18

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '008'
down_revision = '007'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('last_login', sa.DateTime(timezone=True), nullable=True))

def downgrade():
    op.drop_column('users', 'last_login')
