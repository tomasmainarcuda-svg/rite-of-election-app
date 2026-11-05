/*
 * Worship aid (libreto) for the Program tab: the Diocese of Phoenix's own booklet
 * ("Librito para los fieles", Cuaresma 2027), as continuous text in the same order as the
 * printed PDF. Ported from the web app's js/libreto.js.
 *
 * Text: the diocese's Spanish text as printed; the English is our translation of it.
 * Sheet music: the ORIGINAL images cut from the diocese's PDF, published from the staff
 * panel → Firebase roe/libreto/{sectionId}.imgs + roe/libimg/{key}. A "music" block marks
 * where they go. Staff can also replace any section's text from staff.html.
 * Inline **bold** is supported.
 */
import 'models.dart';

/// Block types: p, rubric (grey italic), note (small grey), strong, label, center,
/// resp (who + people's response), list, songs, music.
class Block {
  final String t;
  final L? v;
  final L? who;
  final List<L> items;
  final List<SongRef> songs;
  Block(this.t, {this.v, this.who, this.items = const [], this.songs = const []});
}

class SongRef {
  final String to;
  final L label, song;
  SongRef(this.to, this.label, this.song);
}

class LbSection {
  final String id;
  final L title;
  final L? ref;
  final List<Block> blocks;
  LbSection(this.id, this.title, this.blocks, {this.ref});
  bool get hasMusic => blocks.any((b) => b.t == 'music');
}

class LbPart {
  final String id;
  final L title;
  final L? sub;
  final List<Block> intro;
  final List<LbSection> sections;
  LbPart(this.id, this.title, this.sections, {this.sub, this.intro = const []});
}

// The web helpers take (es, en), like the diocese's booklet (Spanish first).
L _l(String es, [String? en]) => L(en ?? es, es);
Block P(String es, [String? en]) => Block('p', v: _l(es, en));
Block R(String es, [String? en]) => Block('rubric', v: _l(es, en));
Block N(String es, [String? en]) => Block('note', v: _l(es, en));
Block B(String es, [String? en]) => Block('strong', v: _l(es, en));
Block A(String es, String en, [L? who]) => Block('resp', v: _l(es, en), who: who ?? _l('ASAMBLEA', 'ASSEMBLY'));
Block get M => Block('music');

final List<LbPart> libretoParts = [
  LbPart(
    'p-begin',
    _l('Una Iglesia que acompaña', 'A Church that accompanies'),
    sub: _l('Cuaresma 2027 · Diócesis de Phoenix', 'Lent 2027 · Diocese of Phoenix'),
    intro: [
      P(
        'Nos reunimos con el obispo John P. Dolan para acompañar a los catecúmenos de nuestras parroquias. La Iglesia reconoce su preparación y los elige para los sacramentos de la iniciación cristiana: Bautismo, Confirmación y Eucaristía.',
        'We gather with Bishop John P. Dolan to accompany the catechumens of our parishes. The Church recognizes their preparation and chooses them for the sacraments of Christian initiation: Baptism, Confirmation and Eucharist.',
      ),
      P(
        'Los catecúmenos son las personas que todavía no han sido bautizadas. Después de la elección se les llama **elegidos**. Sus padrinos, catequistas, familias y toda la asamblea los sostienen con su oración y su testimonio.',
        'Catechumens are those who have not yet been baptized. After the election they are called the **elect**. Their godparents, catechists, families and the whole assembly support them with their prayer and their witness.',
      ),
      N(
        'Esta guía desarrolla el Rito de Elección de catecúmenos. El rito propio de los candidatos ya bautizados no está incluido.',
        'This guide follows the Rite of Election of catechumens. The rite proper to candidates who are already baptized is not included.',
      ),
    ],
    [
      LbSection('participate', _l('Cómo participar', 'How to take part'), [
        P(
          'Antes de comenzar, guardamos un ambiente de oración. Cantamos las respuestas, escuchamos la Palabra y seguimos las indicaciones de los ministros. Los grupos parroquiales permanecen en sus sectores hasta que se les invite a desplazarse.',
          "Before we begin, we keep a prayerful atmosphere. We sing the responses, listen to the Word and follow the ministers' directions. Parish groups stay in their sections until they are invited to move.",
        ),
        R(
          'Las indicaciones en cursiva describen lo que sucede. El obispo y los ministros utilizan el RICA vigente para los textos propios del rito.',
          'Directions in italics describe what is happening. The bishop and ministers use the current RCIA for the texts proper to the rite.',
        ),
      ]),
      LbSection('songs', _l('Los cantos de esta celebración', 'The music for this celebration'), [
        Block('songs', songs: [
          SongRef('entrance', _l('Canto de entrada', 'Entrance chant'), const L.same('Led by the Spirit')),
          SongRef('psalm', _l('Salmo responsorial', 'Responsorial Psalm'), _l('Salmo 25: Your ways, O Lord', 'Psalm 25: Your ways, O Lord')),
          SongRef('acclamation', _l('Aclamación del Evangelio', 'Gospel acclamation'), const L.same('Glory and praise to you')),
          SongRef('enrollSong', _l('Presentación del Libro de los Elegidos', 'Presentation of the Book of the Elect'), _l('Salmo 33: Blessed the people', 'Psalm 33: Blessed the people')),
          SongRef('intercessions', _l('Respuesta de las intercesiones', 'Response to the intercessions'), const L.same('Lord, hear our prayer')),
          SongRef('recessional', _l('Canto de salida', 'Recessional'), const L.same('Good Shepherd, You Know Us')),
        ]),
        N(
          'Todos los cantos, sus partituras y las respuestas de la asamblea se encuentran en este librito, en el orden de la celebración.',
          "All the songs, their sheet music and the assembly's responses are in this booklet, in the order of the celebration.",
        ),
      ]),
    ],
  ),
  LbPart('p-intro', _l('Ritos iniciales', 'Introductory Rites'), [
    LbSection('entrance', _l('Canto de entrada', 'Entrance chant'), [
      R('De pie · Canto de entrada', 'Please stand · Entrance chant'),
      M,
      R('Cantamos durante la procesión de entrada.', 'We sing during the entrance procession.'),
    ]),
  ]),
  LbPart('p-word', _l('Liturgia de la Palabra', 'Liturgy of the Word'), [
    LbSection('greeting', _l('Señal de la cruz y saludo', 'Sign of the Cross and greeting'), [
      P(
        'El obispo saluda a la asamblea. Respondemos: **Y con tu espíritu.** Al concluir la oración inicial: **Amén.**',
        'The bishop greets the assembly. We respond: **And with your spirit.** At the end of the opening prayer: **Amen.**',
      ),
    ]),
    LbSection('reading1', _l('Primera lectura', 'First reading'), ref: _l('Génesis 9, 8-15', 'Genesis 9:8-15'), [
      P(
        'Sentados. Escuchamos el anuncio de la alianza de Dios con Noé y con todos los seres vivientes.',
        "Please be seated. We hear the proclamation of God's covenant with Noah and with every living creature.",
      ),
      B('Al concluir la lectura: Te alabamos, Señor.', 'At the end of the reading: Thanks be to God.'),
    ]),
    LbSection('psalm', _l('Salmo responsorial', 'Responsorial Psalm'), ref: _l('Salmo 25 (24)', 'Psalm 25 (24)'), [
      M,
      N('La asamblea repite el estribillo después de cada estrofa del salmo.', 'The assembly repeats the refrain after each verse of the psalm.'),
    ]),
  ]),
  LbPart('p-christ', _l('Escuchamos a Cristo', 'We listen to Christ'), [
    LbSection('reading2', _l('Segunda lectura', 'Second reading'), ref: _l('1 Pedro 3, 18-22', '1 Peter 3:18-22'), [
      P(
        'Sentados. Escuchamos cómo la muerte y resurrección de Cristo nos conducen a Dios y cómo el agua anuncia el Bautismo.',
        "Seated. We hear how Christ's death and resurrection lead us to God, and how water foretells Baptism.",
      ),
      A('Te alabamos, Señor.', 'Thanks be to God.'),
    ]),
    LbSection('acclamation', _l('Aclamación del Evangelio', 'Gospel acclamation'), [
      R('De pie. Cantamos la aclamación cuaresmal.', 'Please stand. We sing the Lenten acclamation.'),
      M,
    ]),
    LbSection('gospel', _l('Evangelio', 'Gospel'), ref: _l('Marcos 1, 12-15', 'Mark 1:12-15'), [
      P(
        'Jesús permanece en el desierto y proclama la cercanía del Reino de Dios, llamándonos a la conversión y a la fe.',
        'Jesus remains in the desert and proclaims that the Kingdom of God is at hand, calling us to conversion and faith.',
      ),
      B('Antes de la proclamación: Gloria a ti, Señor.', 'Before the proclamation: Glory to you, O Lord.'),
      B('Al concluir: Gloria a ti, Señor Jesús.', 'At the end: Praise to you, Lord Jesus Christ.'),
    ]),
    LbSection('homily', _l('Homilía', 'Homily'), [
      Block('center', v: _l('**Mons. John P. Dolan**\nObispo de Phoenix', '**Most Rev. John P. Dolan**\nBishop of Phoenix')),
      R('Sentados. Escuchamos la homilía del obispo.', "Seated. We listen to the bishop's homily."),
      N('Después de la homilía comienza la presentación de los catecúmenos.', 'After the homily, the presentation of the catechumens begins.'),
    ]),
  ]),
  LbPart('p-election', _l('Celebración de la elección', 'Celebration of Election'), [
    LbSection('presentation', _l('Presentación de los catecúmenos', 'Presentation of the catechumens'), [
      R(
        'El ministro presenta al obispo a quienes han recorrido el catecumenado y piden ser admitidos a la preparación inmediata para los sacramentos de la iniciación cristiana.',
        'The minister presents to the bishop those who have completed the catechumenate and ask to be admitted to the immediate preparation for the sacraments of Christian initiation.',
      ),
      P(
        'Cada parroquia presenta a sus catecúmenos según el orden establecido. Al escuchar sus nombres, los catecúmenos se ponen de pie junto con sus padrinos. Los coordinadores siguen las indicaciones de los ministros para el uso de los micrófonos y el desplazamiento entre sectores de Chase Field.',
        "Each parish presents its catechumens in the established order. When they hear their names, the catechumens stand with their godparents. Coordinators follow the ministers' directions for the microphones and for moving between sections of Chase Field.",
      ),
    ]),
    LbSection('affirmation', _l('Testimonio de los padrinos', 'Affirmation by the godparents'), [
      R('El obispo pregunta a los padrinos sobre el camino de fe de los catecúmenos:', "The bishop asks the godparents about the catechumens' journey of faith:"),
      P('La escucha fiel de la Palabra de Dios proclamada por la Iglesia.', 'Faithful listening to the Word of God proclaimed by the Church.'),
      A('Sí, lo han hecho.', 'They have.', _l('PADRINOS', 'GODPARENTS')),
      P('La respuesta a esa Palabra y el comienzo de una vida en la presencia de Dios.', "Their response to that Word and the beginning of a life in God's presence."),
      A('Sí, lo han hecho.', 'They have.', _l('PADRINOS', 'GODPARENTS')),
      P('La participación en la comunidad cristiana y en su oración.', 'Sharing in the Christian community and its prayer.'),
      A('Sí, lo han hecho.', 'They have.', _l('PADRINOS', 'GODPARENTS')),
    ]),
    LbSection('assembly', _l('Compromiso de la asamblea', 'Commitment of the assembly'), [
      R(
        'El obispo invita a todos a apoyar el testimonio de los padrinos y a acompañar a los catecúmenos con su oración y su afecto durante el camino hacia la Pascua.',
        "The bishop invites everyone to support the godparents' testimony and to accompany the catechumens with their prayer and affection on the way to Easter.",
      ),
      A('Sí, estamos dispuestos.', 'We are.'),
    ]),
    LbSection('enrollment', _l('Inscripción de los nombres', 'Enrollment of names'), [
      R(
        'El obispo se dirige a los catecúmenos. Después del testimonio de los padrinos y de la comunidad, les pide que manifiesten su deseo de recibir los sacramentos del Bautismo, la Confirmación y la Eucaristía.',
        'The bishop addresses the catechumens. After the testimony of the godparents and the community, he asks them to express their desire to receive the sacraments of Baptism, Confirmation and Eucharist.',
      ),
      A('Sí, queremos.', 'We do.', _l('CATECÚMENOS', 'CATECHUMENS')),
      R(
        'Los representantes parroquiales presentan al obispo el Libro de los Elegidos con los nombres de sus catecúmenos. El movimiento se realiza por grupos y según las indicaciones de los ministros.',
        "Parish representatives present the Book of the Elect, with the names of their catechumens, to the bishop. They move in groups, following the ministers' directions.",
      ),
      P('El representante indica el nombre de su parroquia y presenta los nombres inscritos.', 'Each representative names their parish and presents the enrolled names.'),
    ]),
    LbSection('enrollSong', _l('Canto durante la presentación', 'Song during the presentation'), ref: _l('Salmo 33 (32) · Blessed the people', 'Psalm 33 (32) · Blessed the people'), [M]),
    LbSection('election', _l('Acto de elección', 'Act of election'), [
      R(
        'El obispo declara elegidos a los catecúmenos, admitiéndolos a la preparación para los sacramentos de la iniciación cristiana en la próxima Vigilia Pascual.',
        'The bishop declares the catechumens elect, admitting them to prepare for the sacraments of Christian initiation at the coming Easter Vigil.',
      ),
      A('Demos gracias a Dios.', 'Thanks be to God.', _l('ELEGIDOS', 'THE ELECT')),
    ]),
  ]),
  LbPart(
    'p-accompany',
    _l('Acompañar a los elegidos', 'Accompanying the elect'),
    intro: [
      P(
        'Dios permanece fiel a quienes llama. Los elegidos, junto con toda la comunidad, son invitados a responder con fidelidad y a avanzar con valentía hacia la plenitud de la vida cristiana.',
        'God remains faithful to those he calls. The elect, together with the whole community, are invited to respond faithfully and to move forward with courage toward the fullness of Christian life.',
      ),
    ],
    [
      LbSection('godparents', _l('Encargo a los padrinos', 'Charge to the godparents'), [
        R(
          'El obispo invita a los padrinos a recibir a los elegidos y a sostenerlos con su cercanía, su oración y su ejemplo hasta la celebración de los sacramentos.',
          'The bishop invites the godparents to receive the elect and to support them with their closeness, prayer and example until the celebration of the sacraments.',
        ),
        R('Cuando se les indique, los padrinos colocan la mano sobre el hombro de su ahijado o ahijada.', 'When invited, godparents place a hand on the shoulder of their godchild.'),
      ]),
      LbSection('intercessions', _l('Súplicas por los elegidos', 'Intercessions for the elect'), [
        R(
          'De pie. Nos unimos al obispo para pedir por los elegidos y por toda la Iglesia, llamados a renovar la vida cristiana durante esta Cuaresma.',
          'Please stand. We join the bishop in praying for the elect and for the whole Church, called to renew Christian life this Lent.',
        ),
        Block('label', v: _l('Respuesta cantada', 'Sung response')),
        M,
        Block('center', v: _l('Lord, hear our prayer.\nDeus, exaudi nos.\nSeñor, escúchanos.')),
        R('El ministro proclama las intenciones. Repetimos la respuesta después de cada súplica.', 'The minister proclaims the intentions. We repeat the response after each one.'),
      ]),
      LbSection('community', _l('Oración de la comunidad', 'Prayer of the community'), [
        R('Súplicas por los elegidos y por la Iglesia', 'Intercessions for the elect and for the Church'),
        Block('list', items: [
          _l(
            'Por toda la Iglesia, para que vivamos esta Cuaresma con espíritu de conversión, oración, penitencia y obras de caridad. Roguemos al Señor.',
            'For the whole Church, that we may live this Lent in a spirit of conversion, prayer, penance and works of charity. Let us pray to the Lord.',
          ),
          _l(
            'Por nuestros elegidos, para que recuerden con gratitud este día de su elección y perseveren en el seguimiento de Cristo. Roguemos al Señor.',
            'For our elect, that they may remember the day of their election with gratitude and persevere in following Christ. Let us pray to the Lord.',
          ),
          _l(
            'Por quienes se preparan para la Confirmación y la Eucaristía, para que crezcan cada día en la fidelidad a su Bautismo. Roguemos al Señor.',
            'For those preparing for Confirmation and Eucharist, that they may grow each day in fidelity to their Baptism. Let us pray to the Lord.',
          ),
          _l(
            'Por los catequistas, para que su palabra y su vida ayuden a descubrir la belleza del Evangelio. Roguemos al Señor.',
            'For catechists, that their words and their lives may help others discover the beauty of the Gospel. Let us pray to the Lord.',
          ),
          _l(
            'Por los padrinos y las madrinas, para que sean testigos cercanos de la fe y sostengan a los elegidos con su ejemplo y su oración. Roguemos al Señor.',
            'For godfathers and godmothers, that they may be close witnesses of faith and support the elect with their example and prayer. Let us pray to the Lord.',
          ),
          _l(
            'Por las familias de los elegidos, para que los acompañen con amor y los ayuden a seguir la inspiración del Espíritu Santo. Roguemos al Señor.',
            'For the families of the elect, that they may accompany them with love and help them follow the inspiration of the Holy Spirit. Let us pray to the Lord.',
          ),
          _l(
            'Por quienes todavía dudan en responder al llamado de Dios, para que confíen en Cristo y encuentren acogida entre nosotros. Roguemos al Señor.',
            "For those who still hesitate to answer God's call, that they may trust in Christ and find a welcome among us. Let us pray to the Lord.",
          ),
        ]),
      ]),
      LbSection('prayerElect', _l('Oración sobre los elegidos', 'Prayer over the elect'), [
        R('El obispo pronuncia la oración sobre los elegidos, conforme al RICA.', 'The bishop prays over the elect, according to the RCIA.'),
        A('Amén.', 'Amen.'),
        R('Comentarios finales, si los hubiera.', 'Closing remarks, if any.'),
      ]),
    ],
  ),
  LbPart(
    'p-end',
    _l('Ritos finales', 'Concluding Rites'),
    sub: _l('De pie · Bendición y despedida', 'Please stand · Blessing and dismissal'),
    intro: [
      R('El obispo saluda a la asamblea antes de la bendición.', 'The bishop greets the assembly before the blessing.'),
      A('Y con tu espíritu.', 'And with your spirit.'),
      R('Cuando el diácono lo indique, inclinamos la cabeza para recibir la bendición.', 'When the deacon invites us, we bow our heads to receive the blessing.'),
    ],
    [
      LbSection('blessing', _l('Bendición', 'Blessing'), [
        R(
          'El obispo invoca sobre el pueblo la bendición de Dios: que crezca la esperanza, se fortalezca la fidelidad en las pruebas y todos avancemos hacia la salvación.',
          "The bishop calls down God's blessing on the people: that hope may grow, faithfulness be strengthened in trials, and all of us move forward toward salvation.",
        ),
        A('Amén.', 'Amen.'),
        R('Al concluir la bendición del Padre, del Hijo y del Espíritu Santo, hacemos la señal de la cruz.', 'At the blessing of the Father, the Son and the Holy Spirit, we make the Sign of the Cross.'),
        A('Amén.', 'Amen.'),
      ]),
      LbSection('dismissal', _l('Despedida', 'Dismissal'), [
        R('El diácono despide a la asamblea.', 'The deacon dismisses the assembly.'),
        A('Demos gracias a Dios.', 'Thanks be to God.'),
        R(
          'Cantamos durante la procesión de salida. Los elegidos, sus padrinos y las comunidades parroquiales permanecen en sus lugares hasta recibir las indicaciones de salida.',
          'We sing during the recessional. The elect, their godparents and the parish communities stay in their places until they are given directions to leave.',
        ),
        P(
          'La comunidad sigue acompañando a los elegidos en el tiempo de purificación e iluminación y en la preparación para los sacramentos de Pascua.',
          'The community continues to accompany the elect through the period of purification and enlightenment and their preparation for the Easter sacraments.',
        ),
      ]),
      LbSection('recessional', _l('Canto de salida', 'Recessional'), [
        R('Good Shepherd, You Know Us, You Call Us by Name'),
        M,
        R('Nos unimos en el canto y acompañamos con nuestra oración el camino de los elegidos.', 'We join in the song and accompany the journey of the elect with our prayer.'),
      ]),
    ],
  ),
];

final List<LbSection> libretoSections = [for (final p in libretoParts) ...p.sections];

class LibretoCover {
  static final kicker = _l('Diócesis de Phoenix', 'Diocese of Phoenix');
  static final title = _l('Rito de Elección', 'The Rite of Election');
  static final title2 = _l('de Catecúmenos', 'of Catechumens');
  static const address = '401 E. Jefferson St. · Phoenix, Arizona 85004';
  static final presides = _l('Preside', 'Presiding');
  static final bishop = _l('Mons. John P. Dolan', 'Most Rev. John P. Dolan');
  static final bishopRole = _l('Obispo de Phoenix', 'Bishop of Phoenix');
  static final foot = _l('Librito para los fieles · Cuaresma 2027', 'Worship aid · Lent 2027');
}

/// Speakers whose lines are the people's (shown in gold + bold) in staff-pasted text.
const peopleSpeakers = [
  'ALL', 'TODOS', 'ASSEMBLY', 'ASAMBLEA', 'PEOPLE', 'PUEBLO', 'GODPARENTS', 'PADRINOS', 'CATECHUMENS', //
  'CATECÚMENOS', 'ELECT', 'ELEGIDOS', 'CANDIDATES', 'CANDIDATOS', 'R.', 'R/.',
];
