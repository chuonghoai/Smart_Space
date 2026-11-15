package com.vn.smart_space.model;

import com.vn.smart_space.consts.EMessageType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.BatchSize;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "chat_messages")
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = true)
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = true)
    private Report report;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", length = 32, columnDefinition = "VARCHAR(32)")
    @Builder.Default
    private EMessageType messageType = EMessageType.text;

    @Column(name = "sent_at", nullable = false)
    @Builder.Default
    private LocalDateTime sentAt = LocalDateTime.now();

    @OneToMany(mappedBy = "message", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    @BatchSize(size = 20)
    private List<MessageMedia> mediaFiles = new ArrayList<>();

    public void addMedia(MessageMedia media) {
        if (this.mediaFiles == null) {
            this.mediaFiles = new ArrayList<>();
        }
        this.mediaFiles.add(media);
        media.setMessage(this);
    }
}