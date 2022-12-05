import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.data, required this.mine});

  final Map<String, dynamic> data;

  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: [
          !mine
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(data["sender_photo_url"]),
                  ),
                )
              : Container(),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                data["imageUrl"] != null
                    ? Image.network(
                        data["imageUrl"],
                        width: 250,
                      )
                    : Text(
                        data["text"],
                        textAlign: mine ? TextAlign.end : TextAlign.start,
                        style: const TextStyle(fontSize: 16),
                      ),
                Text(
                  data["sender_name"],
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red),
                ),
              ],
            ),
          ),
          mine
              ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(data["sender_photo_url"]),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
