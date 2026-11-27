# Demo: slug.py → Pascal

```sh
pascal-anything analyze .
pascal-anything bridge . slug.py
python3 -c "from slug import slugify; print(slugify('Hello Pascal'))"
pascal-anything record pascal/slug_pas --inputs inputs.jsonl
# implement port + harness dispatch
pascal-anything build pascal/slug_pas
pascal-anything gate pascal/slug_pas
```
