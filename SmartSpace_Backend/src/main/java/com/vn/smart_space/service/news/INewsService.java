package com.vn.smart_space.service.news;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.news.NewsCreateRequest;
import com.vn.smart_space.dto.request.news.NewsUpdateRequest;
import com.vn.smart_space.dto.response.news.NewsResponse;

public interface INewsService {

    /**
     * Danh sách tin tức mới nhất trước, phân trang (page bắt đầu từ 1).
     * [search] tìm trong tiêu đề / nội dung; [from] / [to] = yyyy-MM-dd theo ngày tạo. null = không lọc.
     */
    PageResponse<NewsResponse> getNews(int page, int size, String search, String from, String to);

    NewsResponse getNewsDetail(String id);

    NewsResponse createNews(NewsCreateRequest request, String adminId);

    NewsResponse updateNews(String id, NewsUpdateRequest request, String adminId);

    void deleteNews(String id, String adminId);
}
