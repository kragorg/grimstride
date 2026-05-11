#!/usr/bin/env python3
import os
import re

MD_FILE = "wildshape/index.md"
MONSTERS_DIR = "../dndrules/ref/monsters"

def main():
    if not os.path.exists(MD_FILE):
        print(f"Error: {MD_FILE} not found.")
        return

    with open(MD_FILE, 'r') as f:
        lines = f.readlines()

    errors = []
    checks_passed = 0

    # Known valid condition names in 5e
    all_conditions = [
        "Blinded", "Charmed", "Deafened", "Exhaustion", "Frightened", 
        "Grappled", "Incapacitated", "Invisible", "Paralyzed", "Petrified", 
        "Poisoned", "Prone", "Restrained", "Stunned", "Unconscious", "Bloodied"
    ]

    # Special D&D Senses
    all_senses = ["Blindsight", "Darkvision", "Tremorsense", "Truesight"]

    for line in lines:
        # Regex to match table rows: | [Name](url) | Speeds | Features |
        match = re.search(r'\|\s*\[([^\]]+)\]\([^\)]+\)\s*\|\s*([^\|]+)\s*\|\s*([^\|]+)\s*\|', line)
        if not match:
            continue
            
        name = match.group(1).strip()
        speeds = match.group(2).strip()
        features_raw = match.group(3).strip()

        filename = name.lower().replace(' ', '-') + '.md'
        filepath = os.path.join(MONSTERS_DIR, filename)

        if not os.path.exists(filepath):
            errors.append(f"[{name}] Source file missing: {filepath}")
            continue

        with open(filepath, 'r') as f:
            source_text = f.read()
            source_lower = source_text.lower()
            source_no_spaces = re.sub(r'\s+', '', source_lower)

        # Clean markdown links from features for easier word parsing
        features_clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', features_raw)

        # 1. Check Speeds (all numbers in the speed column must exist in the source)
        speed_values = re.findall(r'\d+', speeds)
        for v in speed_values:
            if v not in source_text:
                errors.append(f"[{name}] SPEED: '{v}' not found in source.")
            else:
                checks_passed += 1

        # 2. Check Bold Text (Traits, Properties, Special Actions)
        traits = re.findall(r'\*\*([^\*]+)\*\*', features_clean)
        for trait in traits:
            # Remove parentheticals like "Web (recharges)" -> "Web"
            # Remove trailing periods like "Blindsight 10 ft." -> "Blindsight 10 ft"
            t_clean = re.sub(r'\s*\(.*?\)', '', trait).strip().rstrip('.')
            # Senses in source might be wrapped in Markdown links, so strip links from source for this check
            source_no_links = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', source_lower)
            if t_clean.lower() not in source_lower and (t_clean.lower() + ".") not in source_lower and t_clean.lower() not in source_no_links and (t_clean.lower() + ".") not in source_no_links:
                errors.append(f"[{name}] TRAIT/BOLD: '{t_clean}' not found in source.")
            else:
                checks_passed += 1

        # 3. Check Italic Text (Attack Names)
        attacks = re.findall(r'_([^_]+)_', features_clean)
        for attack in attacks:
            if attack.lower() not in source_lower:
                errors.append(f"[{name}] ATTACK/ITALIC: '{attack}' not found in source.")
            else:
                checks_passed += 1

        # 4. Check Conditions
        for cond in all_conditions:
            # We look for the exact word boundary or string
            if re.search(r'\b' + re.escape(cond.lower()) + r'\b', features_clean.lower()):
                if cond.lower() not in source_lower:
                    errors.append(f"[{name}] CONDITION: '{cond}' mentioned in table but not in source.")
                else:
                    checks_passed += 1

        # 5. Check Dice Rolls
        dice_rolls = re.findall(r'\d+d\d+', features_clean)
        for dice in dice_rolls:
            if dice.lower() not in source_lower:
                errors.append(f"[{name}] DICE: '{dice}' not found in source.")
            else:
                checks_passed += 1

        # 6. Check Modifiers (e.g. +5, -1)
        modifiers = re.findall(r'[\+\-−]\s*\d+', features_clean)
        for mod in modifiers:
            # standardize minus signs
            mod_clean = mod.replace('−', '-').replace('--', '-').replace(' ', '').lower()
            if mod_clean not in source_no_spaces:
                # Also check original source just in case
                if mod.lower() not in source_lower:
                    errors.append(f"[{name}] MODIFIER: '{mod}' not found in source.")
            else:
                checks_passed += 1

        # 7. Check DCs
        dcs = re.findall(r'DC\s*\d+', features_clean, re.IGNORECASE)
        for dc in dcs:
            if dc.lower() not in source_lower:
                errors.append(f"[{name}] DC: '{dc}' not found in source.")
            else:
                checks_passed += 1

        # 8. Check Senses
        for sense in all_senses:
            if sense.lower() in features_clean.lower():
                if sense.lower() not in source_lower:
                    errors.append(f"[{name}] SENSE: '{sense}' mentioned but not in source.")
                else:
                    checks_passed += 1

    # Remove duplicates from errors list
    errors = list(set(errors))
    errors.sort()

    if errors:
        print(f"❌ AUDIT FAILED! Found {len(errors)} discrepancies:\n")
        for err in errors:
            print(err)
        return False
    else:
        print(f"✅ AUDIT SUCCESS! {checks_passed} individual mechanics (traits, attacks, speeds, DCs, dice, modifiers, conditions, senses) perfectly matched the source files.")
        return True

if __name__ == "__main__":
    main()
