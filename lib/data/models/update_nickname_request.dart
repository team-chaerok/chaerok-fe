class UpdateNicknameRequest {
  const UpdateNicknameRequest({required this.nickname});

  final String nickname;

  Map<String, dynamic> toJson() => {'nickname': nickname};
}
