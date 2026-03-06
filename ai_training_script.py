"""
SiberKalkan Yapay Zeka Eğitim Betiği (Python)
Bu kod parçasını Google Colab (colab.research.google.com) üzerinde çalıştırıp 
kendi spam_model.tflite dosyanızı üretebilirsiniz.
"""

import tensorflow as tf
import numpy as np
import pandas as pd
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences

# 1. VERİ SETİ (Gerçekte Kaggle'dan indirdiğiniz binlerce satırlık CSV buraya gelecek)
data = {
    'text': [
        'Tebrikler 1000 TL ödül kazandınız, hemen tıklayın',
        'Hesabınız bloke oldu, şifrenizi yenilemek için linke tıklayın',
        'Kredi kartı aidat iadeniz onaylandı, başvurunuzu tamamlayın',
        'Merhaba Fırat, yarın saat 10:00 da toplantımız var',
        'Nasılsın, akşam yemeğe çıkalım mı?',
        'Paketiniz yola çıkmıştır, takip no: 123456'
    ],
    'label': [1, 1, 1, 0, 0, 0] # 1: Zararlı/Dolandırıcı, 0: Temiz
}

df = pd.DataFrame(data)

# 2. METNİ SAYILARA ÇEVİRME (Tokenization)
vocab_size = 1000
max_length = 50
oov_tok = "<OOV>"

tokenizer = Tokenizer(num_words=vocab_size, oov_token=oov_tok)
tokenizer.fit_on_texts(df['text'])
sequences = tokenizer.texts_to_sequences(df['text'])
padded = pad_sequences(sequences, maxlen=max_length, padding='post', truncating='post')

labels = np.array(df['label'])

# 3. YZ MODELİNİ KURMA
model = tf.keras.Sequential([
    tf.keras.layers.Embedding(vocab_size, 16, input_length=max_length),
    tf.keras.layers.GlobalAveragePooling1D(),
    tf.keras.layers.Dense(24, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

# 4. MODELİ EĞİTME
print("🧠 Model çalıştırılıyor ve öğreniyor...")
model.fit(padded, labels, epochs=30, verbose=1)

# 5. TFLITE FORMATINA DÖNÜŞTÜRME
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# 6. APP İÇİN DOSYAYI KAYDETME
with open('spam_model.tflite', 'wb') as f:
    f.write(tflite_model)
    
print("\n✅ Harika! 'spam_model.tflite' başarıyla oluşturuldu.")
print("Bu dosyayı indirip SiberKalkan içindeki assets/models/ klasörüne atabilirsiniz!")
