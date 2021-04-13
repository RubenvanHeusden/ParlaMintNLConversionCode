
# Imports
import os
import json
import requests
from tqdm import tqdm
import lxml.etree as et
from bs4 import BeautifulSoup
from collections import defaultdict
from time import sleep


def clean_name(name):
    name = name.replace('#', '').lower()
    name = name.replace('deheer', '').replace('meneer', '').replace('mevrouw', '')
    name = name.replace('minister', '').replace('staatssecretaris', '').strip()
    if name.split('_')[-1]:
        name = name.replace('_', ' ').replace(' ', '+')
    else:
        name = name.replace('_', '')
    return name


def look_up_name(name_string):
    # make sure string comes in as space separated
    # check that whether the person has a party or not
    query_url = 'https://www.parlement.com/id/vgdei7c2vgu4/zoeken?u=✓&q=%s' % name_string
    a = requests.get(query_url).text
    soup = BeautifulSoup(a, features='lxml')
    try:
        hits = soup.find_all("div", {"class": "zoek_geen_sleutelset"})[0]
        href = 'www.parlement.com' + hits.find('a')['href']

        person = hits.find('li')
        if person.find('span', {"class": "zoek_omg"}):
            positions = person.find('span', {"class": "zoek_omg"}).text.replace(" ", "").lower().split(',')
        else:
            positions = []
        name = person.find_all('div')[-1].text
        name = name[:name.index('(')].strip()

    except:
        return None, None, None

    return name, positions, href


def ground_actors(source_dir):
    namespaces = {'ns': 'http://www.tei-c.org/ns/1.0'}
    actor_dict = {}
    files = os.listdir(source_dir)
    for file in tqdm(files):
        if '.DS_Store' not in file:
            xml_file = et.parse(os.path.join(source_dir, file))
            # .// is is quite inefficient, this can be changed since we know the structure of the file is always
            # exactly the same
            actors = xml_file.xpath('.//ns:u/@who', namespaces=namespaces)
            # set all actors in a dict so that this is unique and we can use that
            # we can 'bind' the found results to the actor names
            for actor in actors:
                actor_dict[actor] = actor

    # now we can do our lookup
    for name in actor_dict.keys():
        grounded_name, functions, link = look_up_name((clean_name(name)))
        if grounded_name:
            id_name = "".join(list(reversed(grounded_name.split(',')))).replace(' ', '').replace('.', '').replace('-', '')
            party = name.split('_')[-1] if (name.split('_')[-1] != '' and len(name.split('_')) > 1) else None
            person_dict = {'id_name': id_name, 'functions': functions, 'grounded_name': grounded_name, 'party': party,
                           'link': link}
            actor_dict[name] = person_dict
        else:
            party = name.split('_')[-1] if name.split('_')[-1] != '' else None
            person_dict = {'id_name': " ".join(name.lower().split('_')[:-1]).replace(' ', ''), 'party': party, 'functions': [],
                           'link': link}
            actor_dict[name] = person_dict

    # Loop through the data again, replacing the original names with the id_name where it exists
    # otherwise leave it as is
    for file in tqdm(files):
        if '.DS_Store' not in file:
            xml_file = et.parse(os.path.join(source_dir, file))
            # .// is is quite inefficient, this can be changed since we know the structure of the file is always
            # exactly the same
            actors = xml_file.xpath('.//ns:u', namespaces=namespaces)
            # set all actors in a dict so that this is unique and we can use that
            # we can 'bind' the found results to the actor names
            for actor in actors:
                if not actor_dict[actor.attrib['who']].get('grounded_name') and (
                        actor_dict[actor.attrib['who']]['party'] is None):
                    actor.attrib['ana'] = '#guest'
                else:
                    old_ana = actor.attrib['ana']
                    if old_ana != '#chair':
                        actor.attrib['ana'] = '#regular'

                actor.attrib['who'] = '#'+actor_dict[actor.attrib['who']]['id_name']

            xml_file.write(os.path.join(source_dir, file), pretty_print=True)

    return actor_dict
