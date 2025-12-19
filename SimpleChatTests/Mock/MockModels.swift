import Foundation
@testable import SimpleChat

extension UserFriend {
    static var stub_1: [UserFriend] {
        [
            UserFriend(email: "ipad5@gmail.com", nickname: "ipad5"),
            UserFriend(email: "ubin8744@gmail.com", nickname: "ubin"),
            UserFriend(email: "ujs@gmail.com", nickname: "jaeseok"),
            UserFriend(email: "hongsg@naver.com", nickname: "hongsg"),
            UserFriend(email: "nicode@gmail.com", nickname: "nicode"),
            UserFriend(email: "dmswns0147@gmail.com", nickname: "dmswns0147"),
        ]
    }
}

extension ApplicationViewModel {

    static var chatroomTitlesStub_1: [String: String] {
        [
            "f674044f-2610-4fc2-a559-89082089add5": "firstChatroom",
            "795bdb98-7356-d68b-126b-cd8aa5b60d44": "jaeseok",
            "231cbd62-37e2-418c-b017-29aeadad3457": "hongsg,ipad5",
            "212ecc0f-f68a-408e-95a1-0a8234fec612": "hongsg",
            "c3d86386-1fec-4d98-bce3-790f519f8cf5": "hongsg,jaeseok,ubin",
            "1344621b-22e0-06e6-0af7-2837b1a33ff4": "nicode"
        ]
    }

    static var whisperMessageStub_1: [String: String] {
        [
            "04f1fe24-10da-4f66-af92-64e0aa84abd0": "hongsg@naver.com",
            "a3b725dd-2cc9-423e-97fd-862714673f09": "hongsg@naver.com",
            "09d27dd7-9169-4a28-8eea-06779a08a942": "ubin8744@gmail.com"
        ]
    }
}

extension UserChatroom {
    static var stub_1: [UserChatroom] {
        [
            UserChatroom(chatroomid: "f674044f-2610-4fc2-a559-89082089add5",
                audiencelist: "dmswns0147@gmail.com nicode@gmail.com",
                roomtype: "GROUP",
                log: []
            ),
            UserChatroom(chatroomid: "c3d86386-1fec-4d98-bce3-790f519f8cf5",
                audiencelist: "hongsg@naver.com ujs@gmail.com ubin8744@gmail.com vivani@gmail.com",
                roomtype: "GROUP",
                log: [
                    SystemLog(id: "a02cf783-08ff-4a83-8e71-253a3d5adb0c", logType: "STARTCHAT", timestamp: "2024-07-20 12:07:17", detail: "ubin8744@gmail.com hongsg@naver.com vivani@gmail.com"),
                    UserChatLog(id: "ba316f36-27a4-4dde-bb9f-4c447c3e5ce8", logType: "TEXT", writer: "ubin8744@gmail.com", timestamp: "2024-07-20 12:15:51", detail: "What are you guys planning to do today? I’m thinking about going outside since the weather is nice.", isSetReadNotification: false, readusers: "ubin8744@gmail.com vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "2b887648-5a20-43fe-b39c-127d8c219d46", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-20 12:16:42", detail: "I’m free today! Going outside sounds great. Do you have any specific plans in mind for us?", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com ubin8744@gmail.com"),
                    UserChatLog(id: "0932b3e5-93d3-4377-8a6d-e05e7c2294db", logType: "TEXT", writer: "hongsg@naver.com", timestamp: "2024-07-20 12:18:37", detail: "Let’s go to the park and enjoy the sunshine. We can have a small picnic and relax.", isSetReadNotification: false, readusers: "ubin8744@gmail.com hongsg@naver.com vivani@gmail.com"),
                    UserChatLog(id: "c948e8f9-9e86-4b42-8d70-6572fd6c1412", logType: "TEXT", writer: "ubin8744@gmail.com", timestamp: "2024-07-20 12:18:47", detail: "That sounds perfect! What time should we meet up at the park? I’m flexible with the time.", isSetReadNotification: false, readusers: "ubin8744@gmail.com hongsg@naver.com vivani@gmail.com"),
                    UserChatLog(id: "3130063f-4356-421e-b1d2-3d0b6040cabd", logType: "TEXT", writer: "hongsg@naver.com", timestamp: "2024-07-20 12:18:57", detail: "How about we meet at 3 PM? I’ll bring some snacks and drinks for everyone. Does that work for you guys?", isSetReadNotification: false, readusers: "hongsg@naver.com ubin8744@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "e75cd2f2-3101-46d7-943d-be4b6b94fdf4", logType: "TEXT", writer: "hongsg@naver.com", timestamp: "2024-07-20 12:19:29", detail: "Also, I’ll bring a blanket for us to sit on. Do we need anything else for our picnic?", isSetReadNotification: false, readusers: "ubin8744@gmail.com vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "42ba2b49-80d1-4623-a5af-97fbcc972517", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-20 12:19:40", detail: "I’ll bring some extra drinks and maybe some games we can play together. This is going to be so much fun!", isSetReadNotification: false, readusers: "hongsg@naver.com vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "3ca24c49-ffca-4840-85ca-1e313b05978d", logType: "TEXT", writer: "ubin8744@gmail.com", timestamp: "2024-07-20 12:19:46", detail: "I’ll bring some fruit and sandwiches for us to share. Can’t wait to see you both at the park!", isSetReadNotification: false, readusers: "vivani@gmail.com ubin8744@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "e3fbee2b-3260-43f7-9aeb-faffd5cd075a", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-20 12:20:02", detail: "Looking forward to it! This will be a great way to spend the afternoon together.", isSetReadNotification: false, readusers: "ubin8744@gmail.com vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "4d523656-5d14-42a1-a3a4-cabc67fe111e", logType: "PHOTO", writer: "vivani@gmail.com", timestamp: "2024-07-21 06:25:55", detail: "photo", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com ubin8744@gmail.com"),
                    UserChatLog(id: "d33c480c-460b-4c3a-b094-a20a19b4cb81", logType: "PHOTO", writer: "vivani@gmail.com", timestamp: "2024-07-21 06:26:03", detail: "photo", isSetReadNotification: false, readusers: "vivani@gmail.com ubin8744@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "9cd341d9-2b0f-46d9-b981-bbc1acdc33fa", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-21 07:51:35", detail: "read notification", isSetReadNotification: false, readusers: "hongsg@naver.com vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "04f1fe24-10da-4f66-af92-64e0aa84abd0", logType: "WHISPER", writer: "vivani@gmail.com", timestamp: "2024-07-22 09:43:29", detail: "the whisper message", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com"),
                    SystemLog(id: "66c78a31-7623-42a0-8983-25795edf3cf4", logType: "EXIT", timestamp: "2024-07-22 13:34:04", detail: "ubin8744@gmail.com"),
                    SystemLog(id: "46a60a0f-61a7-4997-9f23-469d57f0528d", logType: "ENTER", timestamp: "2024-07-24 12:37:56", detail: "vivani@gmail.com ujs@gmail.com"),
                    SystemLog(id: "d542e785-6ecc-45e0-9453-d53b7bbf06e0", logType: "ENTER", timestamp: "2024-07-24 12:37:56", detail: "vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "b7aae29c-2db1-48a9-8078-2d968c14da64", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-24 12:38:29", detail: "ubiin", isSetReadNotification: false, readusers: "vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "09d27dd7-9169-4a28-8eea-06779a08a942", logType: "WHISPER", writer: "vivani@gmail.com", timestamp: "2024-07-24 12:38:37", detail: "ubiin", isSetReadNotification: false, readusers: "vivani@gmail.com ubin8744@gmail.com")
                ]
            ),
            UserChatroom(chatroomid: "231cbd62-37e2-418c-b017-29aeadad3457",
                audiencelist: "ipad5@gmail.com vivani@gmail.com hongsg@naver.com",
                roomtype: "GROUP",
                log: [
                    SystemLog(id: "3c110274-f2f3-47ce-aed0-d44f289516df", logType: "STARTCHAT", timestamp: "2024-07-19 11:17:20", detail: "hongsg@naver.com vivani@gmail.com ipad5@gmail.com"),
                    UserChatLog(id: "0390c2ee-eeb3-49ff-965b-d6d07a419caa", logType: "TEXT", writer: "ipad5@gmail.com", timestamp: "2024-07-19 11:17:26", detail: "very good", isSetReadNotification: false, readusers: "hongsg@naver.com ipad5@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "a3b725dd-2cc9-423e-97fd-862714673f09", logType: "WHISPER", writer: "vivani@gmail.com", timestamp: "2024-07-19 11:18:08", detail: "wisper yo hong", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "34593777-5df1-44d4-91b2-1c31a20692a8", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-19 11:26:43", detail: "이건 내잘못 아니야", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "73b894cc-42d2-40a5-bf7e-1297ca9c7f99", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-20 07:05:36", detail: "It's not my fault", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com")
                ]
            ),
            UserChatroom(chatroomid: "795bdb98-7356-d68b-126b-cd8aa5b60d44",
                audiencelist: "ujs@gmail.com vivani@gmail.com",
                roomtype: "PAIR",
                log: [
                    UserChatLog(id: "ed880f32-549b-4860-a990-523dc82bf973", logType: "BLOCKED", writer: "ujs@gmail.com", timestamp: "2024-07-07 20:41:11", detail: "hmm", isSetReadNotification: false, readusers: "ujs@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "0c11289e-a201-4e32-9294-570401678b73", logType: "TEXT", writer: "ujs@gmail.com", timestamp: "2024-07-07 20:41:20", detail: "hmmm", isSetReadNotification: false, readusers: "ujs@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "7273cee5-d092-491b-8caf-359eb1a2fdcf", logType: "TEXT", writer: "ujs@gmail.com", timestamp: "2024-07-07 20:49:27", detail: "무지성 거인 투하", isSetReadNotification: false, readusers: "ujs@gmail.com vivani@gmail.com")
                ]
            ),
            UserChatroom(chatroomid: "1344621b-22e0-06e6-0af7-2837b1a33ff4",
                audiencelist: "vivani@gmail.com nicode@gmail.com",
                roomtype: "PAIR",
                log: [
                    UserChatLog(id: "1a0650b9-4ed7-4718-9f75-84f54aadff73", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-01 20:42:53", detail: "서버 돌아가고 있지?", isSetReadNotification: false, readusers: "nicode@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "77af865c-6f16-41c7-a4fc-d55aad72e733", logType: "TEXT", writer: "nicode@gmail.com", timestamp: "2024-07-01 20:43:59", detail: "잘돌아가는중", isSetReadNotification: false, readusers: "nicode@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "6eddd8dd-97da-4120-9f53-a8c4f623a36e", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-01 20:52:10", detail: "제발 이만하면 좀 통과해줘라...", isSetReadNotification: false, readusers: "nicode@gmail.com vivani@gmail.com"),
                    UserChatLog(id: "e8622f0c-a71a-4431-a186-a3f41dd51a04", logType: "TEXT", writer: "nicode@gmail.com", timestamp: "2024-07-16 21:11:48", detail: "ㅎ", isSetReadNotification: false, readusers: "vivani@gmail.com nicode@gmail.com"),
                    UserChatLog(id: "04fc4013-978d-4637-b9eb-241182c4d196", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-23 19:34:33", detail: "붉은 여명에 피어나는 꽃처럼....", isSetReadNotification: false, readusers: "vivani@gmail.com")
                ]
            ),
            UserChatroom(chatroomid: "212ecc0f-f68a-408e-95a1-0a8234fec612",
                audiencelist: "hongsg@naver.com vivani@gmail.com",
                roomtype: "GROUP",
                log: [
                    SystemLog(id: "70fdc2f6-6d76-4818-b3c1-85d27aebe21c", logType: "STARTCHAT", timestamp: "2024-07-12 19:36:53", detail: "vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "322707da-89ae-455f-92e1-56ab075651cd", logType: "TEXT", writer: "hongsg@naver.com", timestamp: "2024-07-12 19:37:11", detail: "나보리 신속검 돌려내", isSetReadNotification: false, readusers: "vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "c8093de3-a74e-4dcd-bcbd-cadad1fd3b42", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-13 16:38:25", detail: "돌풍도 돌려줘", isSetReadNotification: false, readusers: "hongsg@naver.com vivani@gmail.com"),
                    SystemLog(id: "35c98b95-34d9-4052-85f1-386100456021", logType: "ENTER", timestamp: "2024-07-13 19:11:59", detail: "vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "dcbdc93d-ed26-412a-8dce-e7e91546d82d", logType: "TEXT", writer: "ubin8744@gmail.com", timestamp: "2024-07-13 21:03:41", detail: "겁쟁이들의 쉼터에 오신것을 환영합니다.", isSetReadNotification: false, readusers: "ubin8744@gmail.com vivani@gmail.com hongsg@naver.com"),
                    UserChatLog(id: "5d27946b-d7b8-426e-8dc5-92cfefe08730", logType: "TEXT", writer: "ubin8744@gmail.com", timestamp: "2024-07-13 21:07:23", detail: "웃기네 이거", isSetReadNotification: false, readusers: "hongsg@naver.com vivani@gmail.com ubin8744@gmail.com"),
                    UserChatLog(id: "e72efe90-ea5c-48a4-8378-02a37e728aae", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-14 01:18:53", detail: "해치웟나", isSetReadNotification: false, readusers: "ubin8744@gmail.com vivani@gmail.com hongsg@naver.com"),
                    SystemLog(id: "001ba74b-6c8d-4f2b-8c19-4a3b1bdee568", logType: "EXIT", timestamp: "2024-07-22 13:35:28", detail: "ubin8744@gmail.com"),
                    UserChatLog(id: "243531a2-ea8c-4c54-9106-a6f77e6da942", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-23 08:40:43", detail: "모두 무대 중앙으로", isSetReadNotification: false, readusers: "hongsg@naver.com vivani@gmail.com"),
                    UserChatLog(id: "f08b9357-4fb8-45b2-b245-a2252fab1925", logType: "TEXT", writer: "vivani@gmail.com", timestamp: "2024-07-23 18:18:03", detail: "학살의 현장에서 난 피어오른다", isSetReadNotification: false, readusers: "vivani@gmail.com")
                ]
            )
        ]
    }
}
