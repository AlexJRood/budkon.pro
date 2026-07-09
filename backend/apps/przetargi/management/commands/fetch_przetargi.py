from django.core.management.base import BaseCommand

from apps.przetargi.services.fetcher import fetch_wszystkie


class Command(BaseCommand):
    help = "Pobiera nowe przetargi z BZP dla wszystkich aktywnych subskrypcji"

    def add_arguments(self, parser):
        parser.add_argument(
            "--company",
            type=int,
            default=None,
            help="Ogranicz do konkretnej firmy (company_id)",
        )

    def handle(self, *args, **options):
        company_id = options.get("company")
        self.stdout.write("Pobieram przetargi z BZP...")

        wyniki = fetch_wszystkie(company_id=company_id)

        total_new = sum(v["new"] for v in wyniki.values())
        total_fetched = sum(v["fetched"] for v in wyniki.values())

        self.stdout.write(
            self.style.SUCCESS(
                f"Gotowe. Pobrano: {total_fetched}, nowych: {total_new} "
                f"(subskrypcji: {len(wyniki)})"
            )
        )
