package com.vn.smart_space.repository;

import java.time.LocalDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.News;

@Repository
public interface NewsRepository extends JpaRepository<News, String> {

    // Từ khoá trong tiêu đề hoặc nội dung; ngày tạo trong [createdFrom, createdTo). null = không lọc.
    String NEWS_FILTER = "WHERE (:search IS NULL OR " +
            "     LOWER(n.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
            "     LOWER(n.content) LIKE LOWER(CONCAT('%', :search, '%'))) " +
            "AND (:createdFrom IS NULL OR n.createdAt >= :createdFrom) " +
            "AND (:createdTo IS NULL OR n.createdAt < :createdTo) ";

    // Mới nhất trước. Fetch author cùng lúc để tránh N+1 khi map authorId / avatar.
    @EntityGraph(attributePaths = { "author" })
    @Query(value = "SELECT n FROM News n " + NEWS_FILTER + "ORDER BY n.createdAt DESC, n.id DESC",
            countQuery = "SELECT COUNT(n) FROM News n " + NEWS_FILTER)
    Page<News> searchNews(
            @Param("search") String search,
            @Param("createdFrom") LocalDateTime createdFrom,
            @Param("createdTo") LocalDateTime createdTo,
            Pageable pageable);
}
