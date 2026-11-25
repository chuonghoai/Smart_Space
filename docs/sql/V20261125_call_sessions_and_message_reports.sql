-- Reference SQL Migration for WebRTC Call Sessions & Multi-Report Chat Attachments
-- Note: SmartSpace_Backend currently runs with spring.jpa.hibernate.ddl-auto=update,
-- which automatically applies these tables/columns on startup. Keep this script for
-- production/manual DBA migrations and auditability.

CREATE TABLE IF NOT EXISTS call_sessions (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    caller_id VARCHAR(255) NOT NULL,
    receiver_id VARCHAR(255) NOT NULL,
    conversation_id VARCHAR(255) NULL,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(24) NOT NULL,
    caller_device_id VARCHAR(100) NULL,
    accepted_device_id VARCHAR(100) NULL,
    created_at DATETIME(6) NOT NULL,
    ringing_at DATETIME(6) NULL,
    accepted_at DATETIME(6) NULL,
    connected_at DATETIME(6) NULL,
    ended_at DATETIME(6) NULL,
    expires_at DATETIME(6) NOT NULL,
    duration_seconds INT NULL,
    end_reason VARCHAR(100) NULL,
    CONSTRAINT fk_call_sessions_caller FOREIGN KEY (caller_id) REFERENCES users (id),
    CONSTRAINT fk_call_sessions_receiver FOREIGN KEY (receiver_id) REFERENCES users (id),
    INDEX idx_call_sessions_caller_status (caller_id, status),
    INDEX idx_call_sessions_receiver_status (receiver_id, status),
    INDEX idx_call_sessions_status_expires (status, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Preserves legacy chat_messages.report_id untouched; adds join table for 1..N attached reports per message
CREATE TABLE IF NOT EXISTS chat_message_reports (
    message_id VARCHAR(255) NOT NULL,
    report_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (message_id, report_id),
    CONSTRAINT fk_cmr_message FOREIGN KEY (message_id) REFERENCES chat_messages (id) ON DELETE CASCADE,
    CONSTRAINT fk_cmr_report FOREIGN KEY (report_id) REFERENCES reports (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional backfill for legacy single-report messages
INSERT IGNORE INTO chat_message_reports (message_id, report_id)
SELECT id, report_id
FROM chat_messages
WHERE report_id IS NOT NULL;
