from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from django.apps import apps
from django.core.management.base import BaseCommand, CommandError
from django.db import models
from PIL import Image


class Command(BaseCommand):
    help = "Generate Toprice DB diagram as PlantUML and render with plantuml.jar."

    DEFAULT_APPS = [
        "users",
        "catalog",
        "ads",
        "analytics",
        "notifications",
        "feedback",
        "subscriptions",
        "wallet",
    ]

    DEFAULT_OUTPUT_DIR = Path("/home/anti-problems/Downloads/uml/db")
    DEFAULT_PLANTUML_JAR = Path("/home/anti-problems/Downloads/uml/plantuml.jar")

    def add_arguments(self, parser):
        parser.add_argument(
            "--output-dir",
            default=str(self.DEFAULT_OUTPUT_DIR),
            help="Directory where db_diagram.puml and rendered files are written.",
        )
        parser.add_argument(
            "--output-name",
            default="db_diagram",
            help="Base filename without extension.",
        )
        parser.add_argument(
            "--plantuml-jar",
            default=str(self.DEFAULT_PLANTUML_JAR),
            help="Path to plantuml.jar.",
        )
        parser.add_argument(
            "--formats",
            default="png,pdf",
            help="Comma-separated render formats (example: png,pdf,svg).",
        )
        parser.add_argument(
            "--apps",
            nargs="*",
            default=self.DEFAULT_APPS,
            help="App labels to include in the diagram.",
        )
        parser.add_argument(
            "--split-by-app",
            action="store_true",
            help="Generate additional per-app diagrams (users+app) for easier reading.",
        )
        parser.add_argument(
            "--unified-detailed",
            action="store_true",
            help="Render the unified diagram with full fields. Default is overview mode (entity names + relations).",
        )
        parser.add_argument(
            "--detailed-layout",
            choices=["balanced", "vertical"],
            default="balanced",
            help="Layout mode for detailed diagrams: balanced (spread across width/height) or vertical.",
        )
        parser.add_argument(
            "--pdf-orientation",
            choices=["auto", "portrait", "landscape"],
            default="auto",
            help="PDF page orientation for generated PDFs.",
        )
        parser.add_argument(
            "--pdf-margin-mm",
            type=float,
            default=8.0,
            help="PDF margin in millimeters.",
        )
        parser.add_argument(
            "--skip-cleanup",
            action="store_true",
            help="Skip cleanup of known non-essential generated files.",
        )
        parser.add_argument(
            "--cleanup-only",
            action="store_true",
            help="Only cleanup known non-essential files; do not regenerate diagram.",
        )
        parser.add_argument(
            "--dry-run-cleanup",
            action="store_true",
            help="Show files that would be deleted without deleting them.",
        )

    def handle(self, *args, **options):
        output_dir = Path(options["output_dir"]).expanduser().resolve()
        output_name = options["output_name"].strip() or "db_diagram"
        plantuml_jar = Path(options["plantuml_jar"]).expanduser().resolve()
        app_labels = list(options["apps"] or self.DEFAULT_APPS)

        output_dir.mkdir(parents=True, exist_ok=True)
        formats = self._parse_formats(options["formats"])

        if not options["cleanup_only"]:
            unified_detailed = bool(options.get("unified_detailed"))
            unified_title = (
                "Toprice Backend - Unified DB Diagram (Detailed)"
                if unified_detailed
                else "Toprice Backend - Unified DB Diagram (Overview)"
            )

            self._generate_one_diagram(
                app_labels=app_labels,
                output_dir=output_dir,
                output_name=output_name,
                plantuml_jar=plantuml_jar,
                formats=formats,
                include_external_refs=False,
                include_fields=unified_detailed,
                layout_mode=options["detailed_layout"],
                title=unified_title,
                pdf_orientation=options["pdf_orientation"],
                pdf_margin_mm=options["pdf_margin_mm"],
            )

            if options["split_by_app"]:
                self._generate_split_diagrams(
                    app_labels=app_labels,
                    output_dir=output_dir,
                    plantuml_jar=plantuml_jar,
                    formats=formats,
                    detailed_layout=options["detailed_layout"],
                    pdf_orientation=options["pdf_orientation"],
                    pdf_margin_mm=options["pdf_margin_mm"],
                )

        if not options["skip_cleanup"]:
            removed = self._cleanup_known_clutter(
                output_dir=output_dir,
                output_name=output_name,
                dry_run=options["dry_run_cleanup"],
            )
            if removed:
                prefix = "Would remove" if options["dry_run_cleanup"] else "Removed"
                self.stdout.write(self.style.WARNING(f"{prefix} {len(removed)} non-essential item(s):"))
                for path in removed:
                    self.stdout.write(f"  - {path}")
            else:
                self.stdout.write("No non-essential files found for cleanup.")

    def _build_puml(
        self,
        app_labels: list[str],
        include_external_refs: bool = False,
        include_fields: bool = True,
        layout_mode: str = "balanced",
        title: str = "Toprice Backend - Unified DB Diagram",
    ) -> str:
        valid_apps = []
        for app_label in app_labels:
            try:
                valid_apps.append(apps.get_app_config(app_label))
            except LookupError:
                self.stdout.write(self.style.WARNING(f"Skipping unknown app label: {app_label}"))

        if not valid_apps:
            raise CommandError("No valid apps were provided; diagram cannot be generated.")

        classes_by_app = {}
        class_order = []
        alias_to_display = {}
        local_aliases = set()
        relations = []
        inheritance_relations = []
        external_bases = {}
        external_relations = {}

        for app_config in valid_apps:
            app_entries = []
            models_in_app = sorted(app_config.get_models(), key=lambda m: m.__name__)
            for model in models_in_app:
                alias = self._alias_for(model)
                local_aliases.add(alias)
                class_order.append(alias)
                alias_to_display[alias] = model.__name__

                fields = self._collect_fields(model)
                app_entries.append((model.__name__, alias, fields))

            classes_by_app[app_config.label] = app_entries

        # Relationships (FK / O2O)
        for app_config in valid_apps:
            for model in app_config.get_models():
                src_alias = self._alias_for(model)
                for field in model._meta.get_fields():
                    if not field.is_relation or not getattr(field, "concrete", False):
                        continue
                    if not (getattr(field, "many_to_one", False) or getattr(field, "one_to_one", False)):
                        continue

                    related_model = getattr(field, "related_model", None)
                    if related_model is None:
                        continue

                    dst_alias = self._alias_for(related_model)
                    if dst_alias in local_aliases:
                        # We draw relation from target to source to match current diagram style.
                        relations.append((dst_alias, src_alias))
                    elif include_external_refs:
                        ext_alias = f"external_{related_model._meta.app_label}_{related_model.__name__}"
                        external_relations[ext_alias] = related_model.__name__
                        alias_to_display[ext_alias] = related_model.__name__
                        relations.append((ext_alias, src_alias))

        # Inheritance relations
        for app_config in valid_apps:
            for model in app_config.get_models():
                src_alias = self._alias_for(model)
                for base in model.__bases__:
                    if not issubclass(base, models.Model):
                        continue
                    if base is models.Model:
                        continue

                    try:
                        base_app = base._meta.app_label
                    except Exception:
                        base_app = None

                    if base_app in classes_by_app:
                        dst_alias = self._alias_for(base)
                    else:
                        dst_alias = f"external_{base.__name__}"
                        external_bases[dst_alias] = base.__name__
                        alias_to_display[dst_alias] = base.__name__

                    inheritance_relations.append(f"{src_alias} --|> {dst_alias}")

        lines = [
            "@startuml",
            f"title {title}",
            (
                "left to right direction"
                if (not include_fields and len(app_labels) > 1)
                or (include_fields and layout_mode == "balanced")
                else "top to bottom direction"
            ),
            "hide circle",
            "hide methods",
            "skinparam classAttributeIconSize 0",
            "skinparam linetype ortho",
            "skinparam packageStyle rectangle",
            "skinparam shadowing false",
            "skinparam defaultFontName Times New Roman",
            f"skinparam classFontSize {'15' if not include_fields else '11'}",
            f"skinparam classAttributeFontSize {'11' if not include_fields else '9'}",
            f"skinparam ranksep {'70' if not include_fields else ('36' if layout_mode == 'balanced' else '45')}",
            f"skinparam nodesep {'38' if not include_fields else ('34' if layout_mode == 'balanced' else '22')}",
            "scale max 1200 width",
            "",
        ]

        for app_label in app_labels:
            entries = classes_by_app.get(app_label)
            if not entries:
                continue

            lines.append(f'package "{app_label}" {{')
            for class_name, alias, field_lines in entries:
                if include_fields:
                    lines.append(f'  class "{class_name}" as {alias} {{')
                    for field_line in field_lines:
                        lines.append(f"    {field_line}")
                    lines.append("  }")
                else:
                    lines.append(f'  class "{class_name}" as {alias}')
            lines.append("}")
            lines.append("")

        if external_bases:
            lines.append('package "External" <<Frame>> {')
            for alias in sorted(external_bases.keys()):
                lines.append(f'  class "{external_bases[alias]}" as {alias} <<external>>')
            lines.append("}")
            lines.append("")

        if external_relations:
            lines.append('package "ExternalRefs" <<Frame>> {')
            for alias in sorted(external_relations.keys()):
                lines.append(f'  class "{external_relations[alias]}" as {alias} <<external>>')
            lines.append("}")
            lines.append("")

        relation_pairs = sorted(set(relations))
        omitted_incoming = {}
        if not include_fields:
            incoming = {}
            for dst_alias, src_alias in relation_pairs:
                incoming.setdefault(dst_alias, []).append(src_alias)

            compact_pairs = []
            max_kept_per_target = 4
            collapse_threshold = 7
            for dst_alias, src_aliases in incoming.items():
                unique_src_aliases = sorted(set(src_aliases))
                if len(unique_src_aliases) <= collapse_threshold:
                    compact_pairs.extend((dst_alias, src_alias) for src_alias in unique_src_aliases)
                    continue

                kept = unique_src_aliases[:max_kept_per_target]
                hidden = unique_src_aliases[max_kept_per_target:]
                compact_pairs.extend((dst_alias, src_alias) for src_alias in kept)
                omitted_incoming[dst_alias] = hidden

            relation_pairs = sorted(set(compact_pairs))

        if include_fields:
            if layout_mode == "balanced":
                # Balanced grid-like hidden links distribute classes across width and height.
                columns = 3 if len(class_order) > 6 else 2
                for idx in range(len(class_order) - 1):
                    relation = "right" if (idx + 1) % columns != 0 else "down"
                    lines.append(f"{class_order[idx]} -[hidden]{relation}- {class_order[idx + 1]}")
            else:
                # Hidden links help keep deterministic top-to-bottom ordering for vertical detailed views.
                for idx in range(len(class_order) - 1):
                    lines.append(f"{class_order[idx]} -[hidden]down- {class_order[idx + 1]}")

            if class_order:
                lines.append("")

        for rel in sorted(set(inheritance_relations)):
            lines.append(rel)
        for dst_alias, src_alias in relation_pairs:
            lines.append(f"{dst_alias} <-- {src_alias}")

        if omitted_incoming:
            lines.append("")
            for dst_alias in sorted(omitted_incoming.keys()):
                hidden_sources = omitted_incoming[dst_alias]
                preview = ", ".join(alias_to_display.get(alias, alias) for alias in hidden_sources[:3])
                suffix = ", ..." if len(hidden_sources) > 3 else ""
                lines.append(f"note right of {dst_alias}")
                lines.append(f"  {len(hidden_sources)} incoming relations hidden for readability")
                if preview:
                    lines.append(f"  hidden: {preview}{suffix}")
                lines.append("end note")

        lines.append("@enduml")
        lines.append("")
        return "\n".join(lines)

    def _generate_one_diagram(
        self,
        app_labels: list[str],
        output_dir: Path,
        output_name: str,
        plantuml_jar: Path,
        formats: list[str],
        include_external_refs: bool,
        include_fields: bool,
        layout_mode: str,
        title: str,
        pdf_orientation: str,
        pdf_margin_mm: float,
    ):
        puml_content = self._build_puml(
            app_labels,
            include_external_refs=include_external_refs,
            include_fields=include_fields,
            layout_mode=layout_mode,
            title=title,
        )
        puml_path = output_dir / f"{output_name}.puml"
        puml_path.write_text(puml_content, encoding="utf-8")
        self.stdout.write(self.style.SUCCESS(f"Wrote {puml_path}"))
        self._render_with_plantuml(
            puml_path=puml_path,
            plantuml_jar=plantuml_jar,
            formats=formats,
            pdf_orientation=pdf_orientation,
            pdf_margin_mm=pdf_margin_mm,
        )

    def _generate_split_diagrams(
        self,
        app_labels: list[str],
        output_dir: Path,
        plantuml_jar: Path,
        formats: list[str],
        detailed_layout: str,
        pdf_orientation: str,
        pdf_margin_mm: float,
    ):
        # Generate one compact diagram per app and keep out-of-scope models as external references.
        for app_label in app_labels:
            subset = [app_label]

            self._generate_one_diagram(
                app_labels=subset,
                output_dir=output_dir,
                output_name=f"db_{app_label}",
                plantuml_jar=plantuml_jar,
                formats=formats,
                include_external_refs=True,
                include_fields=True,
                layout_mode=detailed_layout,
                title=f"Toprice Backend - {app_label.capitalize()} DB Diagram (Detailed)",
                pdf_orientation=pdf_orientation,
                pdf_margin_mm=pdf_margin_mm,
            )

    def _collect_fields(self, model) -> list[str]:
        result = []
        for field in model._meta.get_fields():
            if not getattr(field, "concrete", False):
                continue
            if getattr(field, "auto_created", False):
                continue
            if getattr(field, "many_to_many", False):
                continue

            # Skip default auto id field for cleaner output.
            if field.primary_key and field.name == "id" and isinstance(field, models.AutoField):
                continue
            if field.primary_key and field.name == "id" and isinstance(field, models.BigAutoField):
                continue

            result.append(f"+{field.name}: {self._field_label(field)}")

        return result

    def _field_label(self, field) -> str:
        if isinstance(field, models.OneToOneField):
            return f"o2o -> {field.related_model.__name__}"
        if isinstance(field, models.ForeignKey):
            return f"fk -> {field.related_model.__name__}"

        mappings = [
            (models.EmailField, "email"),
            (models.URLField, "url"),
            (models.SlugField, "slug"),
            (models.PositiveSmallIntegerField, "pos_small_int"),
            (models.PositiveIntegerField, "pos_int"),
            (models.SmallIntegerField, "small_int"),
            (models.BigIntegerField, "bigint"),
            (models.IntegerField, "int"),
            (models.DecimalField, "decimal"),
            (models.FloatField, "float"),
            (models.BooleanField, "bool"),
            (models.DateTimeField, "dt"),
            (models.DateField, "date"),
            (models.TimeField, "time"),
            (models.DurationField, "duration"),
            (models.JSONField, "json"),
            (models.ImageField, "img"),
            (models.FileField, "file"),
            (models.UUIDField, "uuid"),
            (models.TextField, "text"),
            (models.CharField, "str"),
        ]
        for field_type, label in mappings:
            if isinstance(field, field_type):
                return label
        return field.get_internal_type().lower()

    def _alias_for(self, model) -> str:
        return f"{model._meta.app_label}_{model.__name__}"

    def _parse_formats(self, value: str) -> list[str]:
        formats = []
        for item in (value or "").split(","):
            fmt = item.strip().lower()
            if fmt:
                formats.append(fmt)

        if not formats:
            raise CommandError("At least one format is required in --formats.")

        return formats

    def _render_with_plantuml(
        self,
        puml_path: Path,
        plantuml_jar: Path,
        formats: list[str],
        pdf_orientation: str,
        pdf_margin_mm: float,
    ):
        if not plantuml_jar.exists():
            raise CommandError(f"plantuml.jar not found: {plantuml_jar}")
        if shutil.which("java") is None:
            raise CommandError("Java runtime not found in PATH. PlantUML needs java.")

        requested = list(dict.fromkeys(formats))
        needs_pdf = "pdf" in requested

        render_formats = [fmt for fmt in requested if fmt != "pdf"]
        if needs_pdf and "png" not in render_formats:
            render_formats.append("png")

        for fmt in render_formats:
            cmd = [
                "java",
                "-jar",
                str(plantuml_jar),
                f"-t{fmt}",
                "-charset",
                "UTF-8",
                str(puml_path),
            ]
            proc = subprocess.run(cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                stderr = (proc.stderr or "").strip()
                raise CommandError(f"PlantUML failed for format '{fmt}': {stderr}")
            rendered_path = puml_path.with_suffix(f".{fmt}")
            self.stdout.write(self.style.SUCCESS(f"Rendered {rendered_path}"))

        if needs_pdf:
            png_path = puml_path.with_suffix(".png")
            if not png_path.exists():
                raise CommandError(f"PNG source for PDF generation not found: {png_path}")
            pdf_path = puml_path.with_suffix(".pdf")
            self._build_page_fitted_pdf(
                png_path=png_path,
                pdf_path=pdf_path,
                orientation=pdf_orientation,
                margin_mm=pdf_margin_mm,
            )
            self.stdout.write(self.style.SUCCESS(f"Rendered {pdf_path}"))

    def _build_page_fitted_pdf(
        self,
        png_path: Path,
        pdf_path: Path,
        orientation: str,
        margin_mm: float,
    ):
        dpi = 300
        a4_portrait = (2480, 3508)
        a4_landscape = (3508, 2480)

        with Image.open(png_path) as source:
            image = source.convert("RGB")

        if orientation == "portrait":
            page_w, page_h = a4_portrait
        elif orientation == "landscape":
            page_w, page_h = a4_landscape
        else:
            image_ratio = image.width / max(image.height, 1)
            page_w, page_h = a4_landscape if image_ratio > 1.0 else a4_portrait

        margin_px = max(0, int((margin_mm / 25.4) * dpi))
        max_w = max(1, page_w - (2 * margin_px))
        max_h = max(1, page_h - (2 * margin_px))

        scale = min(max_w / image.width, max_h / image.height)
        fitted_w = max(1, int(image.width * scale))
        fitted_h = max(1, int(image.height * scale))

        resized = image.resize((fitted_w, fitted_h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (page_w, page_h), "white")
        paste_x = (page_w - fitted_w) // 2
        paste_y = (page_h - fitted_h) // 2
        canvas.paste(resized, (paste_x, paste_y))
        canvas.save(pdf_path, "PDF", resolution=float(dpi))

    def _cleanup_known_clutter(self, output_dir: Path, output_name: str, dry_run: bool) -> list[Path]:
        to_remove = []

        file_patterns = [
            f"{output_name}_page*.png",
            f"{output_name}_pdf_page*.png",
            f"{output_name}_unified.pdf",
            f"{output_name}.dot",
        ]
        for pattern in file_patterns:
            to_remove.extend(sorted(output_dir.glob(pattern)))

        for folder_name in ["graph_models", "memoire_assets", "__pycache__"]:
            folder = output_dir / folder_name
            if folder.exists() and folder.is_dir():
                to_remove.append(folder)

        removed = []
        for path in to_remove:
            removed.append(path)
            if dry_run:
                continue
            if path.is_dir():
                shutil.rmtree(path, ignore_errors=True)
            else:
                path.unlink(missing_ok=True)

        return removed