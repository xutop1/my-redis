package com.nexp.redis;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MyRedisExerciseApplication {

	public static void main(String[] args) {
		SpringApplication.run(MyRedisExerciseApplication.class, args);
		System.out.println("启动成功");
	}
}
