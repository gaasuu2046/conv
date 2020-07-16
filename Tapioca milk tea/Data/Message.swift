import Foundation
import Firebase

struct messageDataType: Identifiable {
    var id: String
    var name: String
    var message: String
}

class MessageViewModel: ObservableObject {
    @Published var messages = [messageDataType]()
    
    init() {
        let db = Firestore.firestore()
        db.collection("messages").addSnapshotListener { (snap, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let snap = snap {
                for i in snap.documentChanges {
                    if i.type == .added {
                        let name = i.document.get("name") as! String
                        let message = i.document.get("message") as! String
                        let id = i.document.documentID
                        
                        self.messages.append(messageDataType(id: id, name: name, message: message))
                    }
                }
            }
        }
    }
    
    func addMessage(message: String , user: String) {
        // 翻訳対象の言語と、翻訳先言語を指定した上で、Translatorオブジェクトを作成
        let options = TranslatorOptions(sourceLanguage: .ja, targetLanguage: .en)
        let translator = NaturalLanguage.naturalLanguage().translator(options: options)
        
        // ダウンロードオプションを指定。ここで、モバイル回線でのDLの可否を指定することができる
        // Modelのサイズが非常に大きいため、使う状況で適切に切り替えるべき設定
        let conditios = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        
        
        // Modelがローカルになければダウンロードする処理
        // すでにダウンロード済みであればすぐにクロージャ内部の処理が実行される。
        // ダウンロードに時間ががかかるため、ローディング等の表示を行うと良いでしょう。
        translator.downloadModelIfNeeded(with: conditios) { error in
            guard error == nil else { return }
        }
        
        // Modelがダウンロード済みであることが確認できたところで、翻訳実行
        // クロージャで翻訳後の文字列を受け取れる
        translator.translate(message) { translatedText, error in
            guard error == nil, let translatedText = translatedText else {
                print ("tranclation Error")
                return
            }
            print("translatedText: \(translatedText)")
            let data = [
                "message": translatedText,
                "name": user,
                "timestamp": Timestamp(date: Date())
                ] as [String : Any]
            
            let db = Firestore.firestore()
            
            db.collection("messages").addDocument(data: data) { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                print("success")
            }
        }
    }
}

