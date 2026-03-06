# SiberKalkan iOS (iPhone) Entegrasyon Rehberi
## Apple IdentityLookup - ILMessageFilterExtension Kurulumu

Apple, güvenlik nedeniyle iOS uygulamalarının doğrudan gelen SMS'leri okumasına izin vermez. SiberKalkan'ın iOS cihazlarda "Görünmez Kalkan" olarak çalışabilmesi için Xcode üzerinden bir **Message Filter Extension** yazılması zorunludur.

Lütfen uygulamanızı bir Mac bilgisayarda Xcode ile açarak şu adımları uygulayın:

### 1. Xcode'da Extension Eklemek
1. Xcode'da SiberKalkan projenizi (klasördeki `ios/Runner.xcworkspace` dosyası) açın.
2. Üst menüden **File > New > Target...** yolunu izleyin.
3. Çıkan listeden **Message Filter Extension** seçeneğini bulun ve "Next" diyerek ekleyin (İsim olarak `SiberKalkanFilter` verebilirsiniz).

### 2. Çevrimdışı Filtreleme Mantığı (Swift)
Apple, MessageFilter eklentilerinin dışarıya internet bağlantısı (network call) yapmasını engeller. Bu nedenle kelime listeleriniz `CoreData` veya `UserDefaults` (App Groups ile paylaşımlı) üzerinden cihazın içine aktarılmalıdır.

Oluşan `MessageFilterExtension.swift` dosyasına girdiğinizde `handle(_ queryRequest: ILMessageFilterQueryRequest)` fonksiyonunu göreceksiniz. Bu fonksiyonu şu şekilde güncelleyebilirsiniz:

```swift
import IdentityLookup

class MessageFilterExtension: ILMessageFilterExtension {
    // Engellenecek kelime listesi (İdealde ana uygulamadan AppGroups ile okunmalı)
    let spamKeywords = ["tebrikler", "hesabınız bloke", "şifre", "ödül kazandınız", "güncelleme için tıklayın"]

    override func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let response = ILMessageFilterQueryResponse()
        
        guard let messageBody = queryRequest.messageBody?.lowercased() else {
            response.action = .none
            completion(response)
            return
        }

        // Kelime eşleşmesi kontrolü
        var isSpam = false
        for keyword in spamKeywords {
            if messageBody.contains(keyword) {
                isSpam = true
                break
            }
        }

        if isSpam {
            response.action = .junk // veya .promotion, .transaction
        } else {
            response.action = .allow
        }

        completion(response)
    }
}
```

### 3. Kullanıcıyı Yönlendirme
iOS uygulamanızın Flutter arayüzünde (örneğin SMS İzinleri isteği sırasında), cihaz platformu iOS ise kullanıcıya şu mesajı göstermelisiniz:

> "SiberKalkan'ın sizi koruyabilmesi için lütfen **Ayarlar > Mesajlar > Bilinmeyenleri Filtrele** yolunu izleyip SiberKalkan'ı SMS Filtreleme aracı olarak yetkilendirin."
