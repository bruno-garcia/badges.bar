/// Creates an SVG with the dart logo, [title] and [value].
String svg(String title, String value) {
  if (title == null || value == null) {
    throw 'Title and value are required';
  }

  final titleOffset = 27 + (title.length * 2.5);
  final greenStartOffset = 38 + (title.length * 5);

  final valueOffset = 9 + (value.length * 2.5) + greenStartOffset;
  final greenWidth = 18 + (value.length * 5);

  final totalWidth = greenStartOffset + greenWidth;
  // dart:svg only works on the browser
  // flutter_svg only works on .. Flutter
  // So here we go:
  return '''<svg xmlns="http://www.w3.org/2000/svg" width="$totalWidth" height="20">
    <linearGradient id="a" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1" />
        <stop offset="1" stop-opacity=".1" />
    </linearGradient>
    <rect rx="3" width="${totalWidth - 2}" height="20" fill="#555" />
    <rect rx="3" x="$greenStartOffset" width="$greenWidth" height="20" fill="#4c1" />
    <path fill="#4c1" d="M$greenStartOffset 0h4v20h-4z" />
    <rect rx="3" width="$totalWidth" height="20" fill="url(#a)" />
    <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="$titleOffset" y="15" fill="#010101" fill-opacity=".3">$title</text>
        <text x="$titleOffset" y="14">$title</text>
        <text x="$valueOffset" y="15" fill="#010101" fill-opacity=".3">$value</text>
        <text x="$valueOffset" y="14">$value</text>
    </g>
  <g>
   <path fill="#0089f2" d="m4.50676,15.26954l-3.01064,-3.07541c-0.36246,-0.38036 -0.56969,-0.88752 -0.57926,-1.41844c0.02691,-0.28818 0.10504,-0.56897 0.23051,-0.82835l2.78478,-5.91389l0.5746,11.2361l0.00001,0l0,-0.00001z"/>
   <path fill="#40C4FF" d="m14.81711,4.62657l-3.01219,-3.07541c-0.26156,-0.26864 -0.80977,-0.59142 -1.2739,-0.59142c-0.36142,-0.01268 -0.72,0.06867 -1.04184,0.23693l-5.55715,2.83663l10.88508,0.59327z"/>
   <polygon points="8.098284772507782,18.936319047554207 15.396577568699513,18.936319047554207 15.396577568699513,15.74177117421641 9.951701961095296,13.968587178476582 4.972255421244654,15.74177117421641 " fill="#40C4FF"/>
   <path fill="#29B6F6" d="m3.9321,13.61413c0,0.95408 0.11668,1.18309 0.57926,1.65697l0.46724,0.47704l10.42406,0l-5.10208,-5.91706l-6.36848,-5.79608l0,9.57913l0,-0.00001l0,0.00001z"/>
   <path fill="#0089f2" d="m13.1942,4.03342l-9.26218,0l11.46744,11.70838l3.12758,0l0,-7.33234l-3.70994,-3.78279c-0.52027,-0.53436 -0.98259,-0.59327 -1.6229,-0.59327"/>
   <path fill="#FFFFFF" d="m4.62359,15.3887c-0.46724,-0.47704 -0.57952,-0.94299 -0.57952,-1.77451l0,-9.46158l-0.11202,-0.11913l0,9.57913c0,0.83311 0,1.06211 0.6962,1.7761l0.34874,0.35474l-0.35341,-0.35474l0.00001,-0.00001z"/>
   <polygon points="18.408645329585397,8.291923920944782 18.408645329585397,15.623992786978533 15.279759538648932,15.623992786978533 15.396450226995512,15.741804175165498 18.52557417608068,15.741804175165498 18.52557417608068,8.41104834689395 " fill="#0089f2"/>
   <path fill="#FFFFFF" d="m14.81711,4.62657c-0.5746,-0.58666 -1.04494,-0.59327 -1.73803,-0.59327l-9.14705,0l0.11668,0.1194l9.03348,0c0.34435,0 1.21776,-0.05891 1.73648,0.47704l-0.00155,-0.00317l-0.00001,0z"/>
  </g>
</svg>
''';
}
