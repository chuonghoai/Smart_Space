package com.vn.smart_space.service.news;

import java.util.List;

import com.vn.smart_space.dto.request.news.NewsCreateRequest;
import com.vn.smart_space.dto.request.news.NewsUpdateRequest;
import com.vn.smart_space.dto.response.news.NewsResponse;

public interface INewsService {

    List<NewsResponse> getAllNews();

    NewsResponse getNewsDetail(String id);

    NewsResponse createNews(NewsCreateRequest request, String adminId);

    NewsResponse updateNews(String id, NewsUpdateRequest request, String adminId);

    void deleteNews(String id, String adminId);
}
