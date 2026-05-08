class FeedbackRequest {
  const FeedbackRequest({required this.rating, required this.message});

  final int rating;
  final String message;

  Map<String, dynamic> toJson() => {'rating': rating, 'message': message};
}
