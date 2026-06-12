#!/bin/bash
# Dissekt — Meridian Germany + UK
set -e

cd /mnt/d/Startup\ Ideas/Dissekt

# ============================================
# 1. Germany politician database
# ============================================

python3 << 'PYEOF'
import json

germany = {
  "friedrich merz": {"name": "Friedrich Merz", "party": "CDU", "position": "Bundeskanzler", "constituency": "Hochsauerlandkreis", "state": "NRW", "terms": "Chancellor since 2025, MdB since 2002", "key_votes": ["Ukraine military aid expansion", "Migration reform", "Economic reform package"], "key_promises": ["Economic renewal", "Stricter migration policy", "Bundeswehr modernization"], "controversies": ["BlackRock ties", "U-turn on firewall against AfD"], "factual_notes": ["Elected Chancellor Feb 2025 after snap election", "CDU/CSU won 28.5% in 2025 federal election"]},
  "olaf scholz": {"name": "Olaf Scholz", "party": "SPD", "position": "Former Bundeskanzler", "constituency": "Potsdam", "state": "Brandenburg", "terms": "Chancellor 2021-2025, Finance Minister 2018-2021", "key_votes": ["Zeitenwende speech", "€100B Bundeswehr fund", "Energy price cap"], "key_promises": ["Zeitenwende", "Climate neutrality 2045", "€12 minimum wage"], "controversies": ["Cum-Ex scandal", "Warburg Bank meetings", "Scholzomat communication style"], "factual_notes": ["SPD lost to CDU in 2025 snap election", "Presided over energy crisis response"]},
  "robert habeck": {"name": "Robert Habeck", "party": "Grüne", "position": "Former Vice Chancellor", "constituency": "Flensburg", "state": "Schleswig-Holstein", "terms": "Vice Chancellor + Economy Minister 2021-2025", "key_votes": ["Nuclear phase-out", "Heating law (GEG)", "LNG terminals"], "key_promises": ["Green transformation", "Climate-neutral economy"], "controversies": ["Heating law backlash", "Graichen affair", "Nuclear plant shutdown timing"], "factual_notes": ["Greens dropped to ~12% in 2025 election", "Led Germany through energy crisis"]},
  "christian lindner": {"name": "Christian Lindner", "party": "FDP", "position": "Former Finance Minister", "constituency": "NRW", "state": "NRW", "terms": "Finance Minister 2021-2024, FDP Chair since 2013", "key_votes": ["Debt brake defense", "Blocked climate fund"], "key_promises": ["Fiscal discipline", "Tax reform", "Digital transformation"], "controversies": ["Fired by Scholz Nov 2024", "Coalition break memo leak"], "factual_notes": ["FDP fell below 5% threshold in 2025 election", "Firing triggered snap election"]},
  "alice weidel": {"name": "Alice Weidel", "party": "AfD", "position": "AfD Bundestag faction leader", "constituency": "Bodensee", "state": "Baden-Württemberg", "terms": "MdB since 2017, AfD co-chair", "key_votes": ["Opposed all migration laws as too weak", "Anti-EU positions"], "key_promises": ["Dexit referendum", "Zero asylum", "Anti-gender ideology"], "controversies": ["Classified as suspected extremist by BfV", "Correctiv Potsdam meeting report", "Campaign donations"], "factual_notes": ["AfD reached ~20-22% in 2025 election", "Party under domestic intelligence observation"]},
  "sahra wagenknecht": {"name": "Sahra Wagenknecht", "party": "BSW", "position": "BSW founder and leader", "constituency": "NRW", "state": "NRW", "terms": "MdB since 2009, left Die Linke 2024", "key_votes": ["Anti-Ukraine arms delivery", "Anti-NATO expansion"], "key_promises": ["Economic justice", "Diplomatic solution to Ukraine", "Migration limits"], "controversies": ["Left Die Linke to found BSW", "Pro-Russia positioning"], "factual_notes": ["BSW won ~6% in 2025 federal election in first attempt", "Drew voters from both left and right"]},
  "markus soeder": {"name": "Markus Söder", "party": "CSU", "position": "Ministerpräsident Bayern", "constituency": "Nürnberg", "state": "Bavaria", "terms": "Minister-President since 2018", "key_votes": ["Bavarian asylum policy", "Kruzifix decree", "Anti-Greens positioning"], "key_promises": ["Bavaria first", "Tough migration", "Tech hub Bavaria"], "controversies": ["Chancellor ambition 2021 loss to Laschet", "COVID mask deals"], "factual_notes": ["CSU won absolute majority-adjacent in Bavaria 2023", "Key CDU/CSU coalition partner"]},
  "annalena baerbock": {"name": "Annalena Baerbock", "party": "Grüne", "position": "Former Foreign Minister", "constituency": "Potsdam", "state": "Brandenburg", "terms": "Foreign Minister 2021-2025", "key_votes": ["Feminist foreign policy", "China strategy", "Ukraine support"], "key_promises": ["Values-based foreign policy", "Climate diplomacy"], "controversies": ["CV plagiarism 2021", "Book plagiarism allegations"], "factual_notes": ["First female German Foreign Minister", "Led hardline stance on Russia"]},
  "karl lauterbach": {"name": "Karl Lauterbach", "party": "SPD", "position": "Former Health Minister", "constituency": "Leverkusen", "state": "NRW", "terms": "Health Minister 2021-2025, MdB since 2005", "key_votes": ["Cannabis legalization", "Hospital reform", "COVID measures"], "key_promises": ["Hospital reform", "Digital health", "Prevention focus"], "controversies": ["COVID restrictions criticism", "Cannabis law debate"], "factual_notes": ["Epidemiologist by training, Harvard SPH", "Became prominent during COVID pandemic"]},
  "boris pistorius": {"name": "Boris Pistorius", "party": "SPD", "position": "Former Defence Minister", "constituency": "Osnabrück", "state": "Niedersachsen", "terms": "Defence Minister 2023-2025", "key_votes": ["Bundeswehr readiness", "Lithuania brigade", "Conscription debate"], "key_promises": ["War-ready Bundeswehr", "Conscription reform"], "controversies": ["Equipment shortfalls", "Recruitment crisis"], "factual_notes": ["Most popular minister in Scholz cabinet", "Briefly considered as SPD chancellor candidate"]},
  "nancy faeser": {"name": "Nancy Faeser", "party": "SPD", "position": "Former Interior Minister", "constituency": "Hessen", "state": "Hessen", "terms": "Interior Minister 2021-2025", "key_votes": ["Migration policy reform", "AfD ban proceedings", "Border controls"], "key_promises": ["Fight right-wing extremism", "Digitize government"], "controversies": ["Hessen election campaign while minister", "Migration policy criticism"], "factual_notes": ["First female Federal Interior Minister"]},
  "alexander dobrindt": {"name": "Alexander Dobrindt", "party": "CSU", "position": "CSU Landesgruppenchef", "constituency": "Peißenberg", "state": "Bavaria", "terms": "MdB since 2002", "key_votes": ["Transport Minister 2013-17", "Anti-migration hardliner"], "key_promises": ["Conservative values", "Infrastructure"], "controversies": ["PKW-Maut failure", "Anti-asylum rhetoric"], "factual_notes": ["Key CSU voice in Bundestag"]},
  "ricarda lang": {"name": "Ricarda Lang", "party": "Grüne", "position": "Former Grüne co-chair", "constituency": "Stuttgart", "state": "Baden-Württemberg", "terms": "Co-chair 2022-2024", "key_votes": ["Social-ecological transformation"], "key_promises": ["Social justice + climate"], "controversies": ["Resigned after poor election results"], "factual_notes": ["Youngest major party leader at election", "Stepped down 2024"]},
  "janine wissler": {"name": "Janine Wissler", "party": "Die Linke", "position": "Former Die Linke co-chair", "constituency": "Hessen", "state": "Hessen", "terms": "Co-chair 2021-2024", "key_votes": ["Anti-NATO", "Social housing", "Wealth tax"], "key_promises": ["Social justice", "Anti-militarism"], "controversies": ["Party split with Wagenknecht departure"], "factual_notes": ["Die Linke fell below 5% in 2025", "Party in existential crisis after BSW split"]},
  "winfried kretschmann": {"name": "Winfried Kretschmann", "party": "Grüne", "position": "Ministerpräsident Baden-Württemberg", "constituency": "Sigmaringen", "state": "Baden-Württemberg", "terms": "Minister-President since 2011", "key_votes": ["Auto industry transition", "Stuttgart 21 mediation"], "key_promises": ["Green-conservative politics"], "controversies": ["Pro-auto industry stance"], "factual_notes": ["Only Green Minister-President in Germany", "Longest-serving current state leader"]},
}

with open('app/compass/germany_db.json', 'w') as f:
    json.dump(germany, f, indent=2, ensure_ascii=False)
print(f'✅ Germany DB: {len(germany)} politicians')
PYEOF

# ============================================
# 2. UK politician database
# ============================================

python3 << 'PYEOF'
import json

uk = {
  "keir starmer": {"name": "Keir Starmer", "party": "Labour", "position": "Prime Minister", "constituency": "Holborn and St Pancras", "state": "England", "terms": "PM since Jul 2024, Labour leader since 2020", "key_votes": ["Workers Rights Bill", "Rwanda scheme cancellation", "GB Energy creation"], "key_promises": ["5 missions for government", "Clean energy by 2030", "NHS waiting list reduction"], "controversies": ["Freebie/donations row", "Winter fuel payment cut", "Beer and curry Beergate"], "factual_notes": ["Labour won 411 seats in 2024 (landslide)", "Former Director of Public Prosecutions"]},
  "rishi sunak": {"name": "Rishi Sunak", "party": "Conservative", "position": "Former Prime Minister", "constituency": "Richmond and Northallerton", "state": "England", "terms": "PM Oct 2022-Jul 2024, Chancellor 2020-2022", "key_votes": ["Rwanda deportation scheme", "Furlough scheme", "Eat Out to Help Out"], "key_promises": ["Stop the boats", "Halve inflation", "Grow the economy", "Cut NHS waiting lists", "Stop debt rising"], "controversies": ["Non-dom wife tax status", "Green card while Chancellor", "D-Day early departure"], "factual_notes": ["First British Asian PM", "Conservatives won only 121 seats in 2024"]},
  "boris johnson": {"name": "Boris Johnson", "party": "Conservative", "position": "Former Prime Minister", "constituency": "Uxbridge (until 2024)", "state": "England", "terms": "PM 2019-2022, Mayor of London 2008-2016", "key_votes": ["Brexit deal", "COVID lockdowns", "Ukraine military support"], "key_promises": ["Get Brexit Done", "Level up the UK", "40 new hospitals"], "controversies": ["Partygate", "Owen Paterson lobbying", "Chris Pincher affair", "Prorogation ruled unlawful"], "factual_notes": ["Won 80-seat majority 2019", "Resigned after cabinet revolt Jul 2022", "Referred to privileges committee, found to have misled Parliament"]},
  "nigel farage": {"name": "Nigel Farage", "party": "Reform UK", "position": "MP Clacton, Reform UK leader", "constituency": "Clacton", "state": "England", "terms": "MP since 2024, MEP 1999-2020", "key_votes": ["Brexit campaign leader", "Anti-immigration"], "key_promises": ["Immigration freeze", "Reform the state", "Net zero repeal"], "controversies": ["Russia/Putin comments", "Banking debanking row", "Multiple failed parliamentary bids"], "factual_notes": ["Reform UK won 5 seats + 14% vote share in 2024", "Won seat on 8th attempt"]},
  "angela rayner": {"name": "Angela Rayner", "party": "Labour", "position": "Deputy Prime Minister", "constituency": "Ashton-under-Lyne", "state": "England", "terms": "Deputy PM since 2024, Deputy Labour leader since 2020", "key_votes": ["Workers rights expansion", "Housing reform"], "key_promises": ["Workers rights", "Council housing", "Levelling up"], "controversies": ["Council house sale tax investigation (cleared)", "Dancing at Ibiza"], "factual_notes": ["Left school at 16 with no qualifications", "Youngest grandmother in Parliament"]},
  "rachel reeves": {"name": "Rachel Reeves", "party": "Labour", "position": "Chancellor of the Exchequer", "constituency": "Leeds West and Pudsey", "state": "England", "terms": "Chancellor since Jul 2024", "key_votes": ["Autumn Budget 2024", "National Insurance employer rise", "£40B tax rises"], "key_promises": ["Economic stability", "Growth", "Fiscal rules"], "controversies": ["£22B black hole claim", "NI employer tax increase", "CV embellishment"], "factual_notes": ["First female Chancellor in UK history", "Former Bank of England economist"]},
  "jeremy corbyn": {"name": "Jeremy Corbyn", "party": "Independent", "position": "MP Islington North", "constituency": "Islington North", "state": "England", "terms": "MP since 1983, Labour leader 2015-2020", "key_votes": ["Anti-Iraq War", "Anti-austerity", "Anti-nuclear weapons"], "key_promises": ["Public ownership", "Green New Deal", "End austerity"], "controversies": ["Antisemitism crisis in Labour", "Suspended from Labour", "Wreath controversy"], "factual_notes": ["Won seat as independent 2024 after Labour deselection", "Longest continuous backbench service before leadership"]},
  "suella braverman": {"name": "Suella Braverman", "party": "Conservative", "position": "MP Fareham and Waterlooville", "constituency": "Fareham and Waterlooville", "state": "England", "terms": "Home Secretary 2022-2023", "key_votes": ["Rwanda scheme", "Illegal Migration Act"], "key_promises": ["Stop illegal immigration", "Multiculturalism has failed"], "controversies": ["Fired twice as Home Secretary", "Pro-Palestine march comments", "Speeding course row"], "factual_notes": ["First Indian-heritage Home Secretary", "Sacked by Sunak Nov 2023"]},
  "wes streeting": {"name": "Wes Streeting", "party": "Labour", "position": "Health Secretary", "constituency": "Ilford North", "state": "England", "terms": "Health Secretary since Jul 2024", "key_votes": ["NHS reform", "Private sector involvement in NHS"], "key_promises": ["Cut NHS waiting lists", "Preventive care shift", "AI in healthcare"], "controversies": ["Pro-private sector NHS stance", "Kidney cancer survivor"], "factual_notes": ["Grew up in social housing", "Cancer survivor who credits NHS with saving his life"]},
  "david lammy": {"name": "David Lammy", "party": "Labour", "position": "Foreign Secretary", "constituency": "Tottenham", "state": "England", "terms": "Foreign Secretary since Jul 2024, MP since 2000", "key_votes": ["Progressive realism foreign policy", "Ukraine support"], "key_promises": ["Climate diplomacy", "Reconnect with EU"], "controversies": ["Previous Trump criticism before diplomatic reset", "Chagos Islands deal"], "factual_notes": ["First Black British Foreign Secretary", "Harvard Law graduate"]},
  "ed davey": {"name": "Ed Davey", "party": "Liberal Democrats", "position": "Liberal Democrat leader", "constituency": "Kingston and Surbiton", "state": "England", "terms": "Lib Dem leader since 2020, MP since 1997", "key_votes": ["Coalition energy policy 2010-15", "Social care focus"], "key_promises": ["Fix social care", "Sewage in rivers", "NHS dental reform"], "controversies": ["Post Office Horizon scandal responsibility as minister"], "factual_notes": ["Lib Dems won record 72 seats in 2024", "Viral stunts during election campaign"]},
  "john swinney": {"name": "John Swinney", "party": "SNP", "position": "First Minister of Scotland", "constituency": "Perthshire North", "state": "Scotland", "terms": "First Minister since May 2024", "key_votes": ["Independence referendum push", "Scottish budget"], "key_promises": ["Independence", "Public services", "Cost of living"], "controversies": ["Succeeded Humza Yousaf after Sturgeon era", "SNP finances investigation"], "factual_notes": ["SNP dropped from 48 to 9 seats in 2024 UK election", "Second time as SNP leader"]},
  "penny mordaunt": {"name": "Penny Mordaunt", "party": "Conservative", "position": "Former Leader of the Commons", "constituency": "Portsmouth North (lost 2024)", "state": "England", "terms": "Leader of the Commons 2022-2024", "key_votes": ["Defended government in debates", "Naval reserve officer"], "key_promises": ["One Nation conservatism"], "controversies": ["Leadership bid losses 2022", "Viral debate performance"], "factual_notes": ["Lost seat in 2024 election", "First female Defence Secretary (briefly)"]},
  "kemi badenoch": {"name": "Kemi Badenoch", "party": "Conservative", "position": "Leader of the Opposition", "constituency": "North West Essex", "state": "England", "terms": "Conservative leader since Nov 2024", "key_votes": ["Anti-woke agenda", "Gender Recognition Act opposition"], "key_promises": ["Conservative renewal", "Small state", "Honest politics"], "controversies": ["Maternity pay comments", "Civil service clashes", "Cass Review stance"], "factual_notes": ["First Black leader of the Conservative Party", "Born in Nigeria, raised in UK and US"]},
}

with open('app/compass/uk_db.json', 'w') as f:
    json.dump(uk, f, indent=2, ensure_ascii=False)
print(f'✅ UK DB: {len(uk)} politicians')
PYEOF

# ============================================
# 3. Update NER to search all 4 countries
# ============================================

python3 << 'PYEOF'
content = open('app/compass/ner.py').read()

# Update countries list
content = content.replace(
    'countries = ["india", "us"] if country == "all" else [country]',
    'countries = ["india", "us", "germany", "uk"] if country == "all" else [country]'
)

# Add German aliases
if 'merz' not in str(content).lower() or 'ALIASES' in content:
    # Find the ALIASES dict and add German + UK aliases
    old_aliases = '''ALIASES = {
    "aoc": "alexandria ocasio-cortez",
    "raga": "rahul gandhi",
    "pappu": "rahul gandhi",
    "feku": "narendra modi",
    "namo": "narendra modi",
    "kcr": "k chandrashekar rao",
    "cbn": "chandrababu naidu",
    "mbs": "mamata banerjee",
}'''
    
    new_aliases = '''ALIASES = {
    # India
    "aoc": "alexandria ocasio-cortez",
    "raga": "rahul gandhi",
    "pappu": "rahul gandhi",
    "feku": "narendra modi",
    "namo": "narendra modi",
    "kcr": "k chandrashekar rao",
    "cbn": "chandrababu naidu",
    "mbs": "mamata banerjee",
    # Germany
    "scholz": "olaf scholz",
    "habeck": "robert habeck",
    "lindner": "christian lindner",
    "weidel": "alice weidel",
    "wagenknecht": "sahra wagenknecht",
    "soeder": "markus soeder",
    "söder": "markus soeder",
    "baerbock": "annalena baerbock",
    "lauterbach": "karl lauterbach",
    "pistorius": "boris pistorius",
    "kretschmann": "winfried kretschmann",
    # UK
    "starmer": "keir starmer",
    "sunak": "rishi sunak",
    "bojo": "boris johnson",
    "farage": "nigel farage",
    "rayner": "angela rayner",
    "reeves": "rachel reeves",
    "corbyn": "jeremy corbyn",
    "braverman": "suella braverman",
    "badenoch": "kemi badenoch",
}'''
    
    content = content.replace(old_aliases, new_aliases)

open('app/compass/ner.py', 'w').write(content)
print('✅ NER: searches India + US + Germany + UK')
PYEOF

echo ""
echo "✅ Meridian expanded:"
echo ""
echo "  🇩🇪 Germany — 15 politicians"
echo "     Merz, Scholz, Habeck, Lindner, Weidel, Wagenknecht,"
echo "     Söder, Baerbock, Lauterbach, Pistorius, Faeser,"
echo "     Dobrindt, Lang, Wissler, Kretschmann"
echo ""
echo "  🇬🇧 UK — 14 politicians"
echo "     Starmer, Sunak, Johnson, Farage, Rayner, Reeves,"
echo "     Corbyn, Braverman, Streeting, Lammy, Davey,"
echo "     Swinney, Mordaunt, Badenoch"
echo ""
echo "  Total: 30 India + 10 US + 15 Germany + 14 UK = 69 politicians"
echo "  NER searches all 4 countries automatically"
echo ""
echo "Test:"
echo "  python3 -c \""
echo "  from app.compass.ner import detect_politicians"
echo "  r = detect_politicians('Merz and Starmer discussed Ukraine. Scholz criticized the deal. Farage called it a betrayal.')"
echo "  print(f'Found: {len(r)}')"
echo "  for p in r: print(f'  {p[\"name\"]} ({p[\"party\"]}) [{p.get(\"country\")}]')"
echo "  \""
