package com.vn.smart_space;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import com.vn.smart_space.repository.ConversationRepository;

@SpringBootTest
class SmartSpaceApplicationTests {

	@Autowired
	private ConversationRepository conversationRepository;

	@Test
	void contextLoads() {
	}

	@Test
	void testSearchConversation() {
		var page = conversationRepository.findAllByUserIdAndQuery("u1", "nhân", PageRequest.of(0, 10));
		System.out.println("=== FOUND CONVERSATIONS FOR u1 with query 'nhân': " + page.getTotalElements() + " ===");
		for (var c : page.getContent()) {
			System.out.println("Conv: " + c.getId() + " - " + c.getLastMessageContent());
		}
	}

}
