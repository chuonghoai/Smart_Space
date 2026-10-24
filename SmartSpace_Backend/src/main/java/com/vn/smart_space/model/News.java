package com.vn.smart_space.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "news")
public class News extends AbstractEntity {

    @Column(name = "title", nullable = false)
    String title;

    @Column(name = "content", columnDefinition = "LONGTEXT", nullable = false)
    String content;

    @Column(name = "image_urls", columnDefinition = "TEXT")
    String imageUrls;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    User author;

    @Column(name = "author_name")
    String authorName;
}
