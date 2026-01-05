# Proiect Assembly x86 (ASC)
Acest proiect este o aplicație scrisă în limbaj de asamblare (x86) care efectuează operații complexe asupra unui șir de numere hexazecimale introduse de la tastatură.

Proiectul a fost realizat pentru disciplina Arhitectura Sistemelor de Calcul (ASC).

## 📌 Enunțul Temei
Să se scrie un program în limbaj de asamblare care citește de la tastatură un șir de octeți reprezentat în format hexazecimal (caractere `0-9`, `A-F`). Programul trebuie să îndeplinească următoarele cerințe:
1.  Să valideze formatul datelor și lungimea șirului (între 8 și 16 octeți).
2.  Să calculeze un cuvânt de control **C**, format din sume și operații logice asupra octeților.
3.  Să sorteze șirul de octeți în ordine **descrescătoare**.
4.  Să identifice octetul care are cei mai mulți biți de 1 (mai mult de 3).
5.  Să rotească biții fiecărui octet la stânga (`ROL`) cu un număr de poziții egal cu suma ultimilor doi biți și să afișeze rezultatul.

## 📋 Funcționalități Implementate
Programul realizează secvențial următoarele operații:

* **Validare Input:** Verifică dacă șirul introdus conține doar caractere hexazecimale valide și dacă se încadrează în limitele de lungime (8-16). În caz contrar, afișează un mesaj de eroare și reia citirea.
* **Conversie:** Transformă șirul ASCII citit în valori numerice stocate în memorie.
* **Calcul "Cuvânt C":** Determină o valoare pe 16 biți: octetul High este suma octeților, iar octetul Low este rezultatul unor operații logice (`AND`, `SHR`, `XOR`).
* **Sortare:** Ordonează descrescător vectorul de octeți folosind algoritmul *Bubble Sort*.
* **Analiză Biți:** Scanează octeții pentru a-l găsi pe cel cu numărul maxim de biți setați pe 1.
* **Rotire și Afișare:** Aplică rotația pe biți specifică fiecărui octet și afișează rezultatul final atât în format Binar, cât și Hexazecimal.

## 🚀 Rulare
Pentru a compila și executa programul, este necesar un emulator DOS (ex. **DOSBox**) și pachetul **TASM**.

**Comenzi de compilare:**
```bash
tasm main.asm
tlink main.obj
main.exe
