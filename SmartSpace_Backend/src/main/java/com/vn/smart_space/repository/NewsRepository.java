package com.vn.smart_space.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.News;

@Repository
public interface NewsRepository extends JpaRepository<News, String> {

    List<News> findAllByOrderByCreatedAtDesc();
}
