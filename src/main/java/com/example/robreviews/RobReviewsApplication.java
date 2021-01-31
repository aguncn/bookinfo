package com.example.robreviews;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@SpringBootApplication
@Controller
public class RobReviewsApplication {

	public static void main(String[] args) {
		SpringApplication.run(RobReviewsApplication.class, args);
	}


	private final static Boolean ratingsEnabled = true;
	private final static String starColor = System.getenv("STAR_COLOR") == null ? "green" : System.getenv("STAR_COLOR");
	private final static String ratingsService = "http://localhost:8004/ratings";
	private static final String reviewText1 = System.getenv("REVIEW_TEXT_1") == null ? "This play was especially awesome because of its many references to Spring Boot" : System.getenv("REVIEW_TEXT_1");
	private static final String reviewText2 = System.getenv("REVIEW_TEXT_2") == null ? "I personally would have rewritten this play in Rust/Kotlin" : System.getenv("REVIEW_TEXT_2");


	private RestTemplate ratingsTemplate = new RestTemplate();

	class Rating {
		private int stars;
		private String color;

		public int getStars() {
			return stars;
		}

		public void setStars(int stars) {
			this.stars = stars;
		}

		public String getColor() {
			return color;
		}

		public void setColor(String color) {
			this.color = color;
		}
	}

	class ReviewEntry {
		private String reviewer;
		private String text;
		private Rating rating;

		public String getReviewer() {
			return reviewer;
		}

		public void setReviewer(String reviewer) {
			this.reviewer = reviewer;
		}

		public String getText() {
			return text;
		}

		public void setText(String text) {
			this.text = text;
		}

		public Rating getRating() {
			return rating;
		}

		public void setRating(Rating rating) {
			this.rating = rating;
		}
	}


	class Review {
		private String productId;
		private List<ReviewEntry> reviews;

		public String getProductId() {
			return productId;
		}

		public void setProductId(String productId) {
			this.productId = productId;
		}

		public List<ReviewEntry> getReviews() {
			return reviews;
		}

		public void setReviews(List<ReviewEntry> reviews) {
			this.reviews = reviews;
		}
	}

	static class RatingsResponse{

		private Map<String, String> ratings;

		public Map<String, String> getRatings() {
			return ratings;
		}

		public void setRatings(Map<String, String> ratings) {
			this.ratings = ratings;
		}
	}


	@GetMapping(value = "/reviews/{productId}", produces = "application/json")
	public ResponseEntity<Review> getReviews(@PathVariable("productId") String productId,
											   @RequestHeader("end-user") @Nullable String user,
											   @RequestHeader("user-agent") @Nullable String useragent,
											   @RequestHeader("x-request-id") @Nullable String xreq,
											   @RequestHeader("x-b3-traceid") @Nullable String xtraceid,
											   @RequestHeader("x-b3-spanid") @Nullable String xspanid,
											   @RequestHeader("x-b3-parentspanid") @Nullable String xparentspanid,
											   @RequestHeader("x-b3-sampled") @Nullable String xsampled,
											   @RequestHeader("x-b3-flags") @Nullable String xflags,
											   @RequestHeader("x-ot-span-context") @Nullable String xotspan){

		int stars1 = -1;
		int stars2 = -1;



		if(ratingsEnabled) {
			try{
				HttpHeaders headers = new HttpHeaders();
				if(xreq!=null) {
					headers.set("x-request-id",xreq);
				}
				if(xtraceid!=null) {
					headers.set("x-b3-traceid",xtraceid);
				}
				if(xspanid!=null) {
					headers.set("x-b3-spanid",xspanid);
				}
				if(xparentspanid!=null) {
					headers.set("x-b3-parentspanid",xparentspanid);
				}
				if(xsampled!=null) {
					headers.set("x-b3-sampled",xsampled);
				}
				if(xflags!=null) {
					headers.set("x-b3-flags",xflags);
				}
				if(xotspan!=null) {
					headers.set("x-ot-span-context",xotspan);
				}
				if(user!=null) {
					headers.set("end-user", user);
				}
				if(useragent!=null) {
					headers.set("user-agent", useragent);
				}

				HttpEntity<String> entity = new HttpEntity<>(headers);

				RatingsResponse resp = ratingsTemplate.exchange(ratingsService+"/"+productId, HttpMethod.GET, entity, RatingsResponse.class).getBody();
				stars1 = Integer.parseInt(resp.getRatings().get("Reviewer1"));
				stars2 = Integer.parseInt(resp.getRatings().get("Reviewer2"));
			}
			catch(Exception ex) {
				ex.printStackTrace();
			}
		}

		ReviewEntry re1 = new ReviewEntry();
		if(stars1 > 1){
			Rating r1 = new Rating();
			r1.setColor(starColor);
			r1.setStars(stars1);
			re1.setRating(r1);
		}
		re1.setReviewer("Reviewer1");
		re1.setText(reviewText1);

		ReviewEntry re2 = new ReviewEntry();
		if(stars2 > 1){
			Rating r2 = new Rating();
			r2.setColor(starColor);
			r2.setStars(stars2);
			re2.setRating(r2);
		}
		re2.setReviewer("Reviewer2");
		re2.setText(reviewText2);

		List<ReviewEntry> res = new ArrayList<>();
		res.add(re1);
		res.add(re2);

		Review ret = new Review();
		ret.setProductId(productId);
		ret.setReviews(res);

		return ResponseEntity.ok(ret);


	}



}
