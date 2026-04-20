"""010_add_mri_and_teleconsult

Revision ID: 001b2fa19025
Revises: 009
Create Date: 2026-04-19 13:22:34.274692

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001b2fa19025'
down_revision = '009'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Manual Enum Creation (Postgres specific) with existence checks
    def type_exists(name):
        res = op.get_bind().execute(sa.text(f"SELECT 1 FROM pg_type WHERE typname = '{name}'"))
        return res.first() is not None

    if not type_exists('scanstatus'):
        postgresql.ENUM('pending', 'processing', 'completed', 'failed', name='scanstatus').create(op.get_bind())
    if not type_exists('severitysource'):
        postgresql.ENUM('mri_ai', 'doctor_override', 'initial_diagnosis', name='severitysource').create(op.get_bind())
    if not type_exists('teleconsultmode'):
        postgresql.ENUM('in_person', 'teleconsult', name='teleconsultmode').create(op.get_bind())

    op.create_table('patient_mri_scans',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('patient_id', sa.UUID(), nullable=False),
    sa.Column('doctor_id', sa.UUID(), nullable=False),
    sa.Column('filename', sa.String(), nullable=False),
    sa.Column('storage_path', sa.String(), nullable=False),
    sa.Column('checksum', sa.String(), nullable=True),
    sa.Column('status', postgresql.ENUM('pending', 'processing', 'completed', 'failed', name='scanstatus', create_type=False), nullable=True),
    sa.Column('metadata_json', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['doctor_id'], ['users.id'], ondelete='RESTRICT'),
    sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_mri_patient_id', 'patient_mri_scans', ['patient_id'], unique=False)
    op.create_index('idx_mri_status', 'patient_mri_scans', ['status'], unique=False)
    op.create_table('patient_severity_history',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('patient_id', sa.UUID(), nullable=False),
    sa.Column('level_before', sa.Integer(), nullable=True),
    sa.Column('level_after', sa.Integer(), nullable=False),
    sa.Column('source', postgresql.ENUM('mri_ai', 'doctor_override', 'initial_diagnosis', name='severitysource', create_type=False), nullable=False),
    sa.Column('reference_id', sa.UUID(), nullable=True),
    sa.Column('note', sa.Text(), nullable=True),
    sa.Column('is_confirmed', sa.Boolean(), nullable=True),
    sa.Column('confirmed_by', sa.UUID(), nullable=True),
    sa.Column('confirmed_at', sa.DateTime(), nullable=True),
    sa.Column('recorded_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['confirmed_by'], ['users.id'], ondelete='RESTRICT'),
    sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_severity_patient_id', 'patient_severity_history', ['patient_id'], unique=False)
    op.create_table('patient_mri_analysis',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('scan_id', sa.UUID(), nullable=False),
    sa.Column('model_version', sa.String(), nullable=False),
    sa.Column('predicted_level', sa.Integer(), nullable=False),
    sa.Column('confidence', sa.Float(), nullable=False),
    sa.Column('is_uncertain', sa.Boolean(), nullable=True),
    sa.Column('probabilities', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    sa.Column('analysis_notes', sa.Text(), nullable=True),
    sa.Column('analyzed_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['scan_id'], ['patient_mri_scans.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('scan_id')
    )
    op.create_index('idx_analysis_scan_id', 'patient_mri_analysis', ['scan_id'], unique=False)
    op.add_column('appointments', sa.Column('mode', postgresql.ENUM('in_person', 'teleconsult', name='teleconsultmode', create_type=False), nullable=True))
    op.add_column('appointments', sa.Column('meeting_url', sa.String(), nullable=True))
    op.add_column('caretaker_patient', sa.Column('relationship', sa.String(), nullable=True))
    op.execute("UPDATE caretaker_patient SET relationship = relationship_type")
    op.alter_column('caretaker_patient', 'relationship', nullable=False)
    op.drop_column('caretaker_patient', 'relationship_type')
    op.alter_column('patients', 'timezone',
               existing_type=sa.VARCHAR(),
               nullable=True)
    op.alter_column('users', 'under_dispute',
               existing_type=sa.BOOLEAN(),
               nullable=True,
               existing_server_default=sa.text('false'))
    op.alter_column('users', 'last_login',
               existing_type=postgresql.TIMESTAMP(timezone=True),
               type_=sa.DateTime(),
               existing_nullable=True)
    op.alter_column('users', 'updated_at',
               existing_type=postgresql.TIMESTAMP(),
               nullable=True)
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('users', 'updated_at',
               existing_type=postgresql.TIMESTAMP(),
               nullable=False)
    op.alter_column('users', 'last_login',
               existing_type=sa.DateTime(),
               type_=postgresql.TIMESTAMP(timezone=True),
               existing_nullable=True)
    op.alter_column('users', 'under_dispute',
               existing_type=sa.BOOLEAN(),
               nullable=False,
               existing_server_default=sa.text('false'))
    op.alter_column('patients', 'timezone',
               existing_type=sa.VARCHAR(),
               nullable=False)
    op.add_column('caretaker_patient', sa.Column('relationship_type', sa.VARCHAR(), autoincrement=False, nullable=True))
    op.execute("UPDATE caretaker_patient SET relationship_type = relationship")
    op.alter_column('caretaker_patient', 'relationship_type', nullable=False)
    op.drop_column('caretaker_patient', 'relationship')
    op.drop_column('appointments', 'meeting_url')
    op.drop_column('appointments', 'mode')
    op.drop_index('idx_analysis_scan_id', table_name='patient_mri_analysis')
    op.drop_table('patient_mri_analysis')
    op.drop_index('idx_severity_patient_id', table_name='patient_severity_history')
    op.drop_table('patient_severity_history')
    op.drop_index('idx_mri_status', table_name='patient_mri_scans')
    op.drop_index('idx_mri_patient_id', table_name='patient_mri_scans')
    op.drop_table('patient_mri_scans')
    # Manual Enum Drop (Postgres specific)
    op.execute("DROP TYPE teleconsultmode")
    op.execute("DROP TYPE severitysource")
    op.execute("DROP TYPE scanstatus")
    # ### end Alembic commands ###
