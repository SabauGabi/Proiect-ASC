# Procesare Șiruri de Octeți (x86 Assembly)

Acest proiect este o aplicație scrisă în limbaj de asamblare (x86) care efectuează operații complexe asupra unui șir de numere hexazecimale introduse de la tastatură.

Proiectul a fost realizat pentru disciplina **Arhitectura Sistemelor de Calcul (ASC)**.

## 📋 Funcționalități

Programul execută secvențial următoarele operații:

1.  **Citire și Validare:**
    * Preia un șir de octeți în format HEX (ex: `A1 0F 3B`) și validează formatul (0-9, A-F) și lungimea (8-16 octeți).

2.  **Calcul "Cuvânt C":**
    * Calculează o valoare de control pe 16 biți folosind o formulă specifică (suma octeților și operații logice).

3.  **Sortare Descrescătoare:**
    * Ordonează octeții din memorie de la cel mai mare la cel mai mic (Bubble Sort).

4.  **Analiză Biți:**
    * Identifică octetul care conține cei mai mulți biți de 1 (mai mult de 3).

5.  **Rotire pe Biți:**
    * Pentru fiecare octet, aplică o rotire la stânga (`ROL`) bazată pe suma ultimilor 2 biți și afișează rezultatul (Binar | Hex).

## 🚀 Comenzi de Rulare

Pentru a compila și rula programul (folosind TASM):

```bash
tasm main.asm
tlink main.obj
main.exe
