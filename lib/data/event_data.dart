/*
 * Rite of Election — event data (single source of truth for content).
 * Ported from the web app's js/data.js (v1.21.6).
 *
 * IMPORTANT: seat sections, photo groups, stations and photo times are SAMPLE DATA.
 * Every value that still needs confirmation is marked "TBD confirm".
 * Times are "HH:MM" (24 h), Arizona time (MST, UTC-7, no daylight saving).
 */
import 'models.dart';

class Config {
  static const appVersion = '2.0.0';

  /// Firebase Realtime Database (project ecr-mesas, branch "roe") — the same database the
  /// web staff panel and interpreter panel already write to. The app only READS it, over
  /// the REST streaming API, so it needs no Firebase setup inside the iPhone/Android app.
  static const databaseUrl = 'https://ecr-mesas-default-rtdb.firebaseio.com';
  static const dbRoot = 'roe';

  /// Endpoint that receives the altar-call form as JSON (POST). Empty → saved on this phone.
  static const commitSubmitUrl = ''; // TBD confirm (needs backend)

  static const tzOffsetHours = -7; // America/Phoenix
  static const photoSlotMinutes = 30;
  static const meetEarlyMinutes = 15;
  static const photosReleaseNote = L(
    'Your photos will be available to download in this app after the event.',
    'Tus fotos estarán disponibles para descargar en esta app después del evento.',
  ); // TBD confirm delivery method
}

class EventInfo {
  static const name = L('Rite of Election', 'Rito de Elección');
  static const venue = 'Chase Field, Phoenix';
  static const date = '2027-02-20'; // Tomás, Nov 2026 (the web demo still says Feb 13)
  static const liturgyStart = '12:00';
  static const liturgyDurationMin = 60;

  static const schedule = <ScheduleItem>[
    ScheduleItem(
      id: 'doors',
      time: '09:00',
      end: '11:00',
      title: L('Doors open', 'Se abren las puertas'),
      desc: L('Have your digital ticket ready', 'Ten listo tu boleto digital'),
      place: L('Chase Field gates', 'Puertas de Chase Field'), // TBD confirm gates
      accent: 'muted',
      link: 'map',
    ),
    ScheduleItem(
      id: 'photos',
      time: '09:00',
      end: '11:00',
      title: L('Photos with the bishops', 'Fotos con los obispos'),
      desc: L('By parish, at your assigned time', 'Por parroquia, en tu horario asignado'),
      place: L('Warning track, home plate → right field', 'Pista, de home al jardín derecho'),
      accent: 'gold',
      link: 'photos',
    ),
    ScheduleItem(
      id: 'preshow',
      time: '11:00',
      end: '12:00',
      title: L('Opening show', 'Show de apertura'),
      desc: L('Music and welcome — please be in your seat', 'Música y bienvenida — toma tu asiento'),
      place: L('Stage · your parish section', 'Escenario · sección de tu parroquia'),
      accent: 'green2',
      link: 'program',
    ),
    ScheduleItem(
      id: 'liturgy',
      time: '12:00',
      end: '13:00',
      title: L('Rite of Election', 'Rito de Elección'),
      desc: L('The liturgy, with Bishop John Dolan', 'La liturgia, con el obispo John Dolan'),
      place: L('Main stage', 'Escenario principal'),
      accent: 'green',
      link: 'program',
    ),
  ];

  static const notePhotos = L(
    'Photos are taken on the warning track from home plate toward right field.',
    'Las fotos se toman en la pista de advertencia, de home hacia el jardín derecho.',
  );
}

const stations = <Station>[
  Station(1, L('Bishop — TBD', 'Obispo — por confirmar')), // TBD confirm
  Station(2, L('Bishop John Dolan', 'Obispo John Dolan')), // TBD confirm station
  Station(3, L('Bishop — TBD', 'Obispo — por confirmar')), // TBD confirm
];

/* ------------------------------------------------------------------ parishes
 * OFFICIAL LIST: every parish and mission in the Diocese of Phoenix's "Find a Parish"
 * directory (dphx.org/parishes, read Oct 18, 2026): 121 parishes and missions.
 * [diocese id, name, city, "m" = mission]
 */
const _parishList = <List<String>>[
  ['all-saints-catholic-church-mesa', 'All Saints Catholic Church', 'Mesa'],
  ['blessed-sacrament-roman-catholic-church-scottsdale-scottsdale', 'Blessed Sacrament Roman Catholic Church', 'Scottsdale'],
  ['blessed-sacrament-tolleson-tolleson', 'Blessed Sacrament', 'Tolleson'],
  ['chapel-of-the-holy-cross-sedona', 'Chapel of the Holy Cross', 'Sedona', 'm'],
  ['christ-the-king-church-mesa', 'Christ the King Church', 'Mesa'],
  ['church-of-the-ascension-fountain-hills-fountain-hills', 'Church of the Ascension', 'Fountain Hills'],
  ['conventual-church-of-our-lady-of-the-angels-paradise-valley', 'Conventual Church of Our Lady of the Angels', 'Paradise Valley'],
  ['corpus-christi-catholic-church-phoenix', 'Corpus Christi Catholic Church', 'Phoenix'],
  ['location-13846', 'Divine Word Parish', 'Laveen'],
  ['el-cristo-rey-catholic-church-grand-canyon-village', 'El Cristo Rey Catholic Church', 'Grand Canyon Village'],
  ['good-shepherd-catholic-mission-of-st-rose-anthem-new-river', 'Good Shepherd Catholic Mission (of St. Rose, Anthem)', 'New River', 'm'],
  ['good-shepherd-of-the-desert-catholic-church-congress', 'Good Shepherd of the Desert Catholic Church', 'Congress', 'm'],
  ['holy-cross-roman-catholic-parish-mesa', 'Holy Cross Roman Catholic Parish', 'Mesa'],
  ['holy-family-mission-blackwater-coolidge', 'Holy Family Mission Blackwater', 'Coolidge', 'm'],
  ['holy-family-roman-catholic-church-phoenix', 'Holy Family Roman Catholic Church', 'Phoenix'],
  ['holy-family-syro-malabar-catholic-church-phoenix', 'Holy Family Syro Malabar Catholic Church', 'Phoenix'],
  ['holy-spirit-catholic-church-tempe', 'Holy Spirit Catholic Church', 'Tempe'],
  ['immaculate-conception-catholic-church-cottonwood', 'Immaculate Conception Catholic Church', 'Cottonwood'],
  ['immaculate-heart-of-mary-parish-phoenix', 'Immaculate Heart of Mary Parish', 'Phoenix'],
  ['la-santisima-trinidad-church-mission-littlefield', 'La Santísima Trinidad Church Mission', 'Littlefield', 'm'],
  ['mater-misericordiae-catholic-church-phoenix', 'Mater Misericordiae Catholic Church', 'Phoenix', 'm'],
  ['most-holy-trinity-phoenix', 'Most Holy Trinity', 'Phoenix'],
  ['our-lady-of-czestochowa-parish-phoenix', 'Our Lady of Czestochowa Parish', 'Phoenix'],
  ['our-lady-of-fatima-parish-mission-phoenix', 'Our Lady of Fatima Parish Mission', 'Phoenix', 'm'],
  ['our-lady-of-guadalupe-capilla-glendale', 'Our Lady of Guadalupe Capilla', 'Glendale'],
  ['our-lady-of-guadalupe-catholic-church-guadalupe', 'Our Lady of Guadalupe Catholic Church', 'Guadalupe'],
  ['our-lady-of-guadalupe-catholic-church-queen-creek-queen-creek', 'Our Lady of Guadalupe Catholic Church', 'Queen Creek'],
  ['our-lady-of-guadalupe-mission-aguila', 'Our Lady of Guadalupe Mission', 'Aguila', 'm'],
  ['our-lady-of-joy-catholic-church-carefree', 'Our Lady of Joy Catholic Church', 'Carefree'],
  ['our-lady-of-lourdes-church-sun-city-west', 'Our Lady of Lourdes Church', 'Sun City West'],
  ['our-lady-of-mount-carmel-catholic-church-tempe', 'Our Lady of Mount Carmel Catholic Church', 'Tempe'],
  ['our-lady-of-perpetual-help-roman-catholic-church-olph-scottsdale', 'Our Lady of Perpetual Help (OLPH)', 'Scottsdale'],
  ['our-lady-of-perpetual-help-roman-catholic-church-olph-glendale', 'Our Lady of Perpetual Help (OLPH)', 'Glendale'],
  ['our-lady-of-the-desert-roman-catholic-parish-dolan-springs', 'Our Lady of the Desert Roman Catholic Parish', 'Dolan Springs', 'm'],
  ['our-lady-of-the-lake-catholic-school-lake-havasu-city', 'Our Lady of the Lake Catholic Parish', 'Lake Havasu City'],
  ['our-lady-of-the-valley-phoenix', 'Our Lady of the Valley', 'Phoenix'],
  ['our-lady-of-victory-mission-church-sacaton', 'Our Lady of Victory Mission Church', 'Sacaton', 'm'],
  ['prince-of-peace-catholic-parish-sun-city-west', 'Prince of Peace Catholic Parish', 'Sun City West'],
  ['queen-of-peace-catholic-church-and-school-mesa', 'Queen of Peace Catholic Church', 'Mesa'],
  ['resurrection-catholic-church-tempe', 'Resurrection Catholic Church', 'Tempe'],
  ['sacred-heart-catholic-church-phoenix', 'Sacred Heart Catholic Church', 'Phoenix'],
  ['sacred-heart-roman-catholic-parish-prescott-prescott', 'Sacred Heart Roman Catholic Parish', 'Prescott'],
  ['saint-benedict-catholic-church-phoenix', 'Saint Benedict Catholic Church', 'Phoenix'],
  ['saint-catherine-church-mission-laveen-village', 'Saint Catherine Church Mission', 'Laveen Village', 'm'],
  ['saint-juan-diego-catholic-church-chandler', 'Saint Juan Diego Catholic Church', 'Chandler'],
  ['saint-raphael-catholic-church-glendale', 'Saint Raphael Catholic Church', 'Glendale'],
  ['saint-theresa-catholic-church-phoenix', 'Saint Theresa Catholic Church', 'Phoenix'],
  ['san-francisco-de-asis-roman-catholic-church-flagstaff', 'San Francisco de Asís Roman Catholic Church', 'Flagstaff'],
  ['san-lucy-mission-gila-bend-gila-bend', 'San Lucy Mission', 'Gila Bend', 'm'],
  ['santa-teresita-catholic-church-el-mirage', 'Santa Teresita Catholic Church', 'El Mirage'],
  ['saints-simon-and-jude-cathedral-phoenix', 'Ss. Simon and Jude Cathedral', 'Phoenix'],
  ['st-agnes-catholic-church-phoenix', 'St. Agnes Catholic Church', 'Phoenix'],
  ['st-andrew-the-apostle-catholic-church-chandler', 'St. Andrew the Apostle Catholic Church', 'Chandler'],
  ['saint-anne-mission-ash-fork', 'St. Anne Mission', 'Ash Fork', 'm'],
  ['st-anne-mission-santan-santan', 'St. Anne Mission Santan', 'Santan', 'm'],
  ['st-anne-gilbert', 'St. Anne Roman Catholic Parish', 'Gilbert'],
  ['st-anthony-catholic-parish-phoenix', 'St. Anthony Catholic Parish', 'Phoenix'],
  ['st-anthony-church-mission-sacaton', 'St. Anthony Church Mission', 'Sacaton', 'm'],
  ['st-anthony-of-padua-roman-catholic-church-wickenburg', 'St. Anthony of Padua Roman Catholic Church', 'Wickenburg'],
  ['st-augustine-roman-catholic-church-phoenix', 'St. Augustine Roman Catholic Church', 'Phoenix'],
  ['st-bernadette-catholic-church-scottsdale', 'St. Bernadette Catholic Church', 'Scottsdale'],
  ['st-bernard-of-clairvaux-parish-scottsdale', 'St. Bernard of Clairvaux Parish', 'Scottsdale'],
  ['st-bridget-catholic-church-mesa', 'St. Bridget Catholic Church', 'Mesa'],
  ['st-catherine-laboure-parish-chino-valley', 'St. Catherine Labouré Parish', 'Chino Valley'],
  ['st-catherine-of-siena-phoenix-phoenix', 'St. Catherine of Siena', 'Phoenix'],
  ['st-charles-borromeo-peoria', 'St. Charles Borromeo', 'Peoria'],
  ['st-clare-of-assisi-catholic-parish-surprise-surprise', 'St. Clare of Assisi Catholic Parish', 'Surprise'],
  ['st-clement-of-rome-catholic-parish-sun-city', 'St. Clement of Rome Catholic Parish', 'Sun City'],
  ['st-columba-kim-roman-catholic-mission-chandler', 'St. Columba Kim Roman Catholic Mission', 'Chandler', 'm'],
  ['st-daniel-the-prophet-roman-catholic-church-scottsdale', 'St. Daniel the Prophet Roman Catholic Church', 'Scottsdale'],
  ['st-dominic-catholic-mission-rio-verde', 'St. Dominic Catholic Mission', 'Rio Verde', 'm'],
  ['st-edward-the-confessor-phoenix', 'St. Edward the Confessor', 'Phoenix'],
  ['st-elizabeth-seton-sun-city', 'St. Elizabeth Seton', 'Sun City'],
  ['st-frances-cabrini-catholic-church-camp-verde', 'St. Frances Cabrini Catholic Church', 'Camp Verde'],
  ['st-francis-of-assisi-salt-river-scottsdale', 'St. Francis of Assisi – Salt River', 'Scottsdale', 'm'],
  ['st-francis-of-assisi-mission-ak-chin-maricopa', 'St. Francis of Assisi Mission – Ak-Chin', 'Maricopa', 'm'],
  ['st-francis-of-assisi-parish-bagdad-bagdad', 'St. Francis of Assisi Parish', 'Bagdad'],
  ['st-francis-xavier-parish-and-school-phoenix', 'St. Francis Xavier Parish', 'Phoenix'],
  ['st-gabriel-the-archangel-church-cave-creek', 'St. Gabriel the Archangel Church', 'Cave Creek'],
  ['st-germaine-parish-prescott-valley-prescott-valley', 'St. Germaine Parish', 'Prescott Valley'],
  ['st-gregory-parish-phoenix', 'St. Gregory Parish', 'Phoenix'],
  ['st-helen-roman-catholic-parish-glendale-glendale', 'St. Helen Roman Catholic Parish', 'Glendale'],
  ['st-henry-roman-catholic-parish-buckeye', 'St. Henry Roman Catholic Parish', 'Buckeye'],
  ['st-james-the-greater-roman-catholic-church-glendale', 'St. James the Greater Roman Catholic Church', 'Glendale'],
  ['st-jerome-roman-catholic-parish-phoenix-phoenix', 'St. Jerome Roman Catholic Parish', 'Phoenix'],
  ['st-joachim-and-st-anne-parish-sun-city-sun-city', 'St. Joachim and St. Anne Parish', 'Sun City'],
  ['st-joan-of-arc-phoenix', 'St. Joan of Arc', 'Phoenix'],
  ['st-john-the-baptist-parish-laveen-laveen', 'St. John the Baptist Parish', 'Laveen'],
  ['st-john-vianney-goodyear', 'St. John Vianney Parish', 'Goodyear'],
  ['st-john-vianney-sedona-sedona', 'St. John Vianney', 'Sedona'],
  ['st-joseph-mission-mayer-mayer', 'St. Joseph Mission', 'Mayer', 'm'],
  ['st-joseph-parish-phoenix-phoenix', 'St. Joseph Parish', 'Phoenix'],
  ['st-joseph-the-worker-williams', 'St. Joseph the Worker', 'Williams'],
  ['st-josephine-bakhita-mission-parish-st-pius-x-phoenix', 'St. Josephine Bakhita Mission Parish / St. Pius X', 'Phoenix'],
  ['st-louis-the-king-roman-catholic-parish-glendale', 'St. Louis the King Roman Catholic Parish', 'Glendale'],
  ['st-luke-parish-phoenix', 'St. Luke Parish', 'Phoenix'],
  ['st-margaret-mary-parish-bullhead-city', 'St. Margaret Mary Parish', 'Bullhead City'],
  ['st-margaret-parish-tempe-tempe', 'St. Margaret Parish', 'Tempe'],
  ['st-maria-goretti-scottsdale', 'St. Maria Goretti', 'Scottsdale'],
  ['st-mark-parish-phoenix-phoenix', 'St. Mark Parish', 'Phoenix'],
  ['st-martin-de-porres-phoenix', 'St. Martin de Porres', 'Phoenix'],
  ['st-mary-magdalene-gilbert', 'St. Mary Magdalene', 'Gilbert'],
  ['st-mary-roman-catholic-church-kingman', 'St. Mary Roman Catholic Church', 'Kingman'],
  ['st-mary-roman-catholic-parish-chandler-chandler', 'St. Mary Roman Catholic Parish', 'Chandler'],
  ['st-marys-roman-catholic-basilica-phoenix', "St. Mary's Roman Catholic Basilica", 'Phoenix'],
  ['st-matthew-phoenix', 'St. Matthew', 'Phoenix'],
  ['st-michael-catholic-church-gila-bend', 'St. Michael Catholic Church', 'Gila Bend'],
  ['st-paschal-baylon-chapel-scottsdale', 'St. Paschal Baylon Chapel', 'Scottsdale', 'm'],
  ['st-patrick-catholic-community-scottsdale', 'St. Patrick Catholic Community', 'Scottsdale'],
  ['st-paul-roman-catholic-church-phoenix-phoenix', 'St. Paul Roman Catholic Church', 'Phoenix'],
  ['st-philip-benizi-catholic-church-black-canyon-city', 'St. Philip Benizi Catholic Church', 'Black Canyon City', 'm'],
  ['st-philip-the-deacon-phoenix', 'St. Philip the Deacon', 'Phoenix', 'm'],
  ['st-rose-philippine-duchesne-catholic-parish-anthem', 'St. Rose Philippine Duchesne Catholic Parish', 'Anthem'],
  ['st-stevens-catholic-church-sun-lakes', "St. Steven's Catholic Church", 'Sun Lakes'],
  ['st-thomas-aquinas-catholic-church-and-school-avondale', 'St. Thomas Aquinas Catholic Church', 'Avondale'],
  ['st-thomas-more-glendale', 'St. Thomas More', 'Glendale'],
  ['st-thomas-the-apostle-phoenix', 'St. Thomas the Apostle', 'Phoenix'],
  ['st-timothy-catholic-church-mesa', 'St. Timothy Catholic Church', 'Mesa'],
  ['st-vincent-de-paul-parish-phoenix-phoenix', 'St. Vincent de Paul Parish', 'Phoenix'],
  ['st-william-catholic-parish-cashion', 'St. William Catholic Parish', 'Cashion'],
  ['vietnamese-martyrs-catholic-church-phoenix', 'Vietnamese Martyrs Catholic Church', 'Phoenix'],
];

/// Old sample ids (before Oct 18) → so phones that chose a parish in the demo keep it.
const _aliases = <String, String>{
  'st-marys-roman-catholic-basilica-phoenix': 'st-marys-basilica',
  'st-joseph-parish-phoenix-phoenix': 'st-joseph-phx',
  'our-lady-of-guadalupe-catholic-church-queen-creek-queen-creek': 'olg-chandler',
  'st-thomas-the-apostle-phoenix': 'st-thomas-apostle',
  'st-francis-xavier-parish-and-school-phoenix': 'st-francis-xavier',
  'san-francisco-de-asis-roman-catholic-church-flagstaff': 'san-francisco-flagstaff',
  'st-timothy-catholic-church-mesa': 'st-timothy-mesa',
  'most-holy-trinity-phoenix': 'most-holy-trinity',
  'saint-theresa-catholic-church-phoenix': 'st-theresa-phx',
  'saints-simon-and-jude-cathedral-phoenix': 'ss-simon-jude',
  'st-patrick-catholic-community-scottsdale': 'st-patrick-scottsdale',
  'st-mary-roman-catholic-parish-chandler-chandler': 'st-mary-chandler',
};

const lowerSections = ['124', '125', '126', '127', '128', '129', '130', '131', '132', '133', '134', '135']; // TBD confirm

String _initials(String name) {
  final skip = RegExp(r'^(Catholic|Roman|Church|Parish|Mission|Of|The)$', caseSensitive: false);
  final upper = RegExp(r'^[A-ZÁÉÍÓÚ]');
  final words = name.replaceAll(RegExp(r'\(.*?\)'), '').split(RegExp(r'[\s/–-]+'));
  final s = words.where((w) => w.isNotEmpty && upper.hasMatch(w) && !skip.hasMatch(w)).map((w) => w[0]).join();
  return s.length > 4 ? s.substring(0, 4) : s;
}

String _at(int mins) => '${(9 + mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';

/// MOCK for every parish (Tomás, Oct 18: "invent a time, it's a mock"): seat sections cycle
/// through the lower bowl, photo groups rotate across the 3 stations, a new group every
/// 5 minutes from 9:00 AM. All TBD — replace with the real plan.
final List<Parish> parishes = List.generate(_parishList.length, (i) {
  final row = _parishList[i];
  return Parish(
    id: row[0],
    name: row[1],
    city: row[2],
    mission: row.length > 3 && row[3] == 'm',
    code: _initials(row[1]),
    section: lowerSections[i % lowerSections.length],
    group: i + 1,
    station: (i % 3) + 1,
    photoStart: _at(5 * (i ~/ 3)),
    size: 25 + ((i * 7) % 30),
    alias: _aliases[row[0]],
  );
});

/* ------------------------------------------------- translation channels */
const channels = <Channel>[
  Channel('es', 'Español', 'es'),
  Channel('vi', 'Tiếng Việt', 'vi'),
];
const englishOption = Channel('en', 'English', 'en', none: true);

/* ------------------------------------------------------------------- map */
class MapData {
  static const parkingLat = 33.4455; // TBD: Tomás picks the exact spot
  static const parkingLng = -112.0667;
  static const gates = <Gate>[
    Gate('home', 'A', L('Home plate gate', 'Puerta de home')), // TBD confirm
    Gate('left', 'B', L('Left field gate', 'Puerta del jardín izquierdo')), // TBD confirm
    Gate('right', 'C', L('Right field gate', 'Puerta del jardín derecho')), // TBD confirm
  ];
}

/* ------------------------------------------------------------------ info */
const infoItems = <InfoItem>[
  InfoItem(
    'parking',
    L('Parking', 'Estacionamiento'),
    L(
      'Parking is still being arranged with the Arizona Diamondbacks. Lots, prices and directions will be posted here once confirmed. Carpooling with your parish is encouraged.',
      'El estacionamiento todavía se está acordando con los Arizona Diamondbacks. Publicaremos aquí los lotes, precios e indicaciones cuando estén confirmados. Te animamos a compartir auto con tu parroquia.',
    ),
  ),
  InfoItem(
    'food',
    L('Food and concessions', 'Comida y concesiones'),
    L(
      'Food will be available for purchase on the main concourse. This is an alcohol-free event.',
      'Habrá comida a la venta en el pasillo principal. Es un evento sin alcohol.',
    ),
  ),
  InfoItem(
    'access',
    L('Accessibility', 'Accesibilidad'),
    L(
      'Chase Field has elevators, accessible seating and accessible restrooms. If someone in your group needs accessible seating or help getting to the photo stations, let your OCIA or RE director know ahead of time, and ask any volunteer on the day.',
      'Chase Field tiene elevadores, asientos accesibles y baños accesibles. Si alguien de tu grupo necesita un asiento accesible o ayuda para llegar a las estaciones de fotos, avísale con anticipación a tu director de OCIA o de Educación Religiosa, y pide ayuda a cualquier voluntario ese día.',
    ),
  ),
  InfoItem(
    'bring',
    L('What to bring', 'Qué traer'),
    L(
      "Your digital ticket on your phone · a charged phone · earbuds if you'll use live translation · comfortable shoes. Please check the stadium bag policy before you come.",
      'Tu boleto digital en el teléfono · el teléfono cargado · audífonos si vas a usar la traducción en vivo · zapatos cómodos. Revisa la política de bolsas del estadio antes de venir.',
    ),
  ),
];

/* ------------------------------------------------------------------ news
 * MOCK for the demo (Oct 16, 2026): REAL stories from The Catholic Sun (LOCAL section of
 * catholicsun.org/feed), real headline, date, author, photo and link; short summaries in our
 * own words. Later this should be pulled live from the Catholic Sun feed.
 */
const news = <NewsItem>[
  NewsItem(
    id: 'st-matthew-school',
    type: 'article',
    date: '2026-10-19',
    source: 'The Catholic Sun',
    title: L('St. Matthew Catholic School: a dual language curriculum rooted in Christ', 'Escuela Católica St. Matthew: un programa bilingüe arraigado en Cristo'),
    summary: L(
      'Founded in 1943, the Phoenix school is the only one in Arizona with its bilingual, biliterate English–Spanish program, and faith is woven into the whole school day.',
      'Fundada en 1943, esta escuela de Phoenix es la única de Arizona con su programa bilingüe inglés–español, y la fe está presente en toda la jornada escolar.',
    ),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/DSC_0116-scaled.jpg',
    link: 'https://www.catholicsun.org/2026/10/19/st-matthew-catholic-school-a-dual-language-curriculum-rooted-in-christ/',
  ),
  NewsItem(
    id: 'deacons-2026',
    type: 'article',
    date: '2026-10-16',
    source: 'The Catholic Sun',
    title: L('Six men to be ordained permanent deacons', 'Seis hombres serán ordenados diáconos permanentes'),
    summary: L(
      'The ordination is Nov. 7 at 10 a.m. at Ss. Simon and Jude Cathedral in Phoenix.',
      'La ordenación será el 7 de noviembre a las 10 a.m. en la Catedral de los Santos Simón y Judas, en Phoenix.',
    ),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/office-diaconate-2.jpg',
    link: 'https://www.catholicsun.org/2026/10/16/six-men-to-be-ordained-permanent-deacons/',
  ),
  NewsItem(
    id: 'come-as-you-are',
    type: 'article',
    date: '2026-10-15',
    source: 'Debbie DiCarlo',
    title: L('Come as you are', 'Ven tal como eres'),
    summary: L(
      'A personal reflection on the Eucharist as the place where we are known, loved and invited to begin again.',
      'Una reflexión personal sobre la Eucaristía como el lugar donde somos conocidos, amados e invitados a empezar de nuevo.',
    ),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/DSC3538-scaled.jpg',
    link: 'https://www.catholicsun.org/2026/10/15/come-as-you-are/',
  ),
  NewsItem(
    id: 'dolan-pope-remarks',
    type: 'video',
    date: '2026-10-13',
    source: 'The Catholic Sun',
    title: L('Bishop Dolan’s remarks on Pope Leo XIV’s cancer diagnosis', 'Palabras del obispo Dolan sobre el diagnóstico de cáncer del papa León XIV'),
    summary: L(
      'In a video message, the Bishop invites the faithful to pray for the Holy Father.',
      'En un mensaje en video, el obispo invita a los fieles a rezar por el Santo Padre.',
    ),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/20261013T0930-POPE-LEO-SURGERY-TODAY-1828204.jpg',
    link: 'https://www.catholicsun.org/2026/10/13/bishop-dolans-remarks-on-pope-leo-xivs-cancer-diagnosis/',
  ),
  NewsItem(
    id: 'avila-ribbon',
    type: 'article',
    date: '2026-10-13',
    source: 'The Catholic Sun',
    title: L('Avila University Arizona celebrates ribbon cutting', 'Avila University Arizona inaugura su campus'),
    summary: L('The Goodyear campus marked its official inauguration on Oct. 8.', 'El campus de Goodyear celebró su inauguración oficial el 8 de octubre.'),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/AUA-Ribbon-Cutting-1-2.jpg',
    link: 'https://www.catholicsun.org/2026/10/13/avila-university-arizona-celebrates-ribbon-cutting/',
  ),
  NewsItem(
    id: 'veterans-mass',
    type: 'article',
    date: '2026-10-13',
    source: 'Jeff Grant',
    title: L('Diocese of Phoenix invites the faithful to join Mass honoring, praying for veterans', 'La Diócesis de Phoenix invita a la Misa en honor y oración por los veteranos'),
    summary: L(
      'The Red, White and Blue Mass is Sunday, Nov. 8, at 11 a.m. at All Saints in Mesa.',
      'La Misa Red, White and Blue será el domingo 8 de noviembre a las 11 a.m. en All Saints, Mesa.',
    ),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/wesley-tingey-QVLOprz-H7s-unsplash.jpg',
    link: 'https://www.catholicsun.org/2026/10/13/diocese-of-phoenix-invites-the-faithful-to-join-mass-honoring-praying-for-veterans/',
  ),
  NewsItem(
    id: 'world-mission-100',
    type: 'article',
    date: '2026-10-11',
    source: 'Catherine Mulhern',
    title: L('One hundred years of World Mission Sunday', 'Cien años del Domingo Mundial de las Misiones'),
    summary: L('The worldwide day of prayer and support for the missions turns 100.', 'La jornada mundial de oración y apoyo a las misiones cumple 100 años.'),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/55177368643_1958be41a0_o.jpg',
    link: 'https://www.catholicsun.org/2026/10/11/one-hundred-years-of-world-mission-sunday/',
  ),
  NewsItem(
    id: 'comms-summit',
    type: 'article',
    date: '2026-10-09',
    source: 'The Catholic Sun',
    title: L('Diocese of Phoenix hosts first-ever Communications Summit', 'La Diócesis de Phoenix realiza su primera Cumbre de Comunicaciones'),
    summary: L('Nearly 100 people from 48 parishes gathered at the Diocesan Pastoral Center.', 'Casi 100 personas de 48 parroquias se reunieron en el Centro Pastoral Diocesano.'),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/841140189_1462772309104812_617527237919263793_n-e1791586693583.jpeg',
    link: 'https://www.catholicsun.org/2026/10/09/diocese-of-phoenix-hosts-first-ever-communications-summit-for-nearly-50-parishes/',
  ),
  NewsItem(
    id: 'st-mary-basha',
    type: 'article',
    date: '2026-10-08',
    source: 'The Catholic Sun',
    title: L('St. Mary-Basha Catholic School breaks ground on new Art and Athletics Center', 'St. Mary-Basha Catholic School inicia las obras de su nuevo Centro de Arte y Deportes'),
    summary: L('Bishop Dolan blessed the start of construction at the Chandler school.', 'El obispo Dolan bendijo el inicio de las obras en la escuela de Chandler.'),
    image: 'https://catechism-dphx.s3.amazonaws.com/wp-content/uploads/2026/10/DSC_1542.jpg',
    link: 'https://www.catholicsun.org/2026/10/08/st-mary-basha-catholic-school-breaks-ground-on-new-art-and-athletics-center/',
  ),
];

const faqs = <Faq>[
  Faq(
    L('Do I need a ticket?', '¿Necesito boleto?'),
    L(
      'Yes. Tickets are free, digital general admission, issued through the Arizona Diamondbacks. Your parish OCIA or RE director will send you the registration link.',
      'Sí. Los boletos son gratuitos, digitales y de admisión general, emitidos por los Arizona Diamondbacks. Tu director de OCIA o de Educación Religiosa te enviará el enlace de registro.',
    ),
  ),
  Faq(
    L('Can my family come?', '¿Puede venir mi familia?'),
    L(
      'Yes, families and friends are welcome! Please sit with your parish section. Photos with the bishops are only for catechumens, candidates and their sponsors.',
      '¡Sí, familiares y amigos son bienvenidos! Por favor siéntense en la sección de su parroquia. Las fotos con los obispos son solo para catecúmenos, candidatos y sus padrinos.',
    ),
  ),
  Faq(
    L('Where do I sit?', '¿Dónde me siento?'),
    L(
      'With your parish, in its assigned section. Choose your parish on the Home screen or open the Map.',
      'Con tu parroquia, en su sección asignada. Elige tu parroquia en Inicio o abre el Mapa.',
    ),
  ),
  Faq(
    L('What time should I arrive?', '¿A qué hora debo llegar?'),
    L(
      "Doors open at 9:00 AM. Photos run from 9:00 to 11:00 AM: if you're in a photo group, check your photo time. Everyone else: please be seated by 11:00 AM for the opening show. The liturgy begins at 12:00 PM.",
      'Las puertas se abren a las 9:00 AM. Las fotos son de 9:00 a 11:00 AM: si estás en un grupo de fotos, revisa tu horario. Todos los demás: por favor estén sentados a las 11:00 AM para el show de apertura. La liturgia empieza a las 12:00 PM.',
    ),
  ),
  Faq(
    L('Will there be translation?', '¿Habrá traducción?'),
    L(
      'Yes. Live audio in Spanish, English and Vietnamese in the Translate tab. Bring earbuds.',
      'Sí. Audio en vivo en español, inglés y vietnamita en la pestaña Traducción. Trae audífonos.',
    ),
  ),
  Faq(
    L('Is there a printed booklet?', '¿Habrá un folleto impreso?'),
    L(
      'No. Follow along in the Program tab. Lyrics and readings will also be on the stadium screens.',
      'No. Sigue la celebración en la pestaña Programa. Las letras y lecturas también estarán en las pantallas del estadio.',
    ),
  ),
];

const videos = <Video>[
  Video('dolan', L('A welcome from Bishop John Dolan', 'Bienvenida del Obispo John Dolan'), ''), // TBD confirm
  Video('bishops', L('A message from our bishops', 'Un mensaje de nuestros obispos'), ''), // TBD confirm
];

class Contact {
  static const name = L('Diocese of Phoenix — Rite of Election team', 'Diócesis de Phoenix — equipo del Rito de Elección');
  static const email = ''; // TBD confirm
  static const phone = ''; // TBD confirm
}
