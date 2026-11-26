package com.vn.smart_space.configuration.async;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/** Executor riêng cho việc gửi SMS/FCM để không chặn request (vd. tạo SOS phải trả về ngay). */
@Configuration
public class NotificationExecutorConfig {

    public static final String SOS_NOTIFICATION_EXECUTOR = "sosNotificationExecutor";

    @Bean(name = SOS_NOTIFICATION_EXECUTOR)
    public ThreadPoolTaskExecutor sosNotificationExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(8);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("sos-notify-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(20);
        executor.initialize();
        return executor;
    }
}
