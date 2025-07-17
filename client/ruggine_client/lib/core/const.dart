
//API paths
import 'package:ruggine_client/config.dart';

final String apibase = AppConfig.apiBaseUrl;
final String websocketUrl = AppConfig.webSocketUrl;
const String apipath_register = "auth/register";
const String apipath_login = "auth/login";
const String apipath_user = "user";
const String apipath_new_messages = "chatMessages";
const String apipath_send_msg = "sendMessage";
const String apipath_chat_info = "chatInfo";
const String apipath_new_chat = "groups";

  // inviti
const String apipath_invites = "groupInvites";
const String apipath_accept_invite = "groupInvites/accept";

//Route constants
const String route_login = "/login";
const String route_home = "/";


// Secure Storage Keys
const String kHivePath = 'hive_path';
const String kJwtTokenKey = 'jwt_token';
const String kChatsBox = 'chats_box';
const String kInvitesBox = 'invites_box';
const String kMessagesBox = 'messages_box';
const String kLastUpdateBox = 'last_update_box';