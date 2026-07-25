import 'package:flutter/material.dart';

/// Temel 101 Okey kurallarını özetleyen statik bilgi ekranı.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const _sections = [
    (
      'Taşlar ve Okey',
      '106 taş: 4 renk (kırmızı, siyah, mavi, sarı), 1-13 arası her '
          'sayıdan 2 kopya, artı 2 sahte okey. Taşlar karıştırıldıktan '
          'sonra bir gösterge taşı çekilir; okey, göstergeyle aynı renkte '
          'bir fazla sayıdır (13 ise 1 olur).',
    ),
    (
      'Dağıtım ve Sıra',
      'Başlayan oyuncu 22, diğerleri 21 taş alır. Her oyuncu sırasında '
          'kapalı desteden veya ortadaki açık taştan bir taş çeker, '
          'isterse per açar/masaya taş işler, ardından bir taş atarak '
          'sırayı bir sonraki oyuncuya devreder.',
    ),
    (
      'Seri ve Grup',
      'Seri: aynı renkte, ardışık en az 3 taş. Grup: aynı sayıda, '
          'farklı renklerden en az 3 taş. Okey, herhangi bir taşın yerine '
          'geçebilir.',
    ),
    (
      '101 Açılış',
      'Bir oyuncu ilk kez per açarken, açtığı taşların toplam değeri en '
          'az 101 (masaya göre değişebilir) olmalıdır. Yetersizse açılış '
          'reddedilir.',
    ),
    (
      'Bitiş',
      'Bir oyuncu elindeki tüm taşları geçerli perlere döküp son taşını '
          'atarak (veya çiftten/elden) eli bitirir. Açılmamış oyuncuların '
          'elinde kalan taşlar ceza puanı olarak sayılır.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kurallar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final (title, body) = _sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(body),
            ],
          );
        },
      ),
    );
  }
}
