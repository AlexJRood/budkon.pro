// docs/widgets/template_editor/template_editor_syntax.dart

import 'template_editor_models.dart';

class TemplateEditorSyntax {
  static final RegExp fieldRegex = RegExp(
    r'\{\s*(?:\.{3}|…)\s*\{\s*([^{}\[\]\r\n]{1,140}?)\s*\}\s*(?::\s*\[([^\]]*)\]\s*)?(?:\.{3}|…)\s*\}',
    multiLine: true,
  );

  static final RegExp segmentRegex = RegExp(
    r'\{\s*(?:\.{3}|…)\s*\[\s*(\/?segment)(?::\s*([^\]]*?))?\s*\]\s*(?:\.{3}|…)\s*\}',
    multiLine: true,
  );

  static TemplateEditorTokenMatch? tokenAtPosition(String text, int position) {
    for (final match in fieldRegex.allMatches(text)) {
      if (position >= match.start && position <= match.end) {
        return TemplateEditorTokenMatch(
          kind: TemplateEditorTokenKind.field,
          start: match.start,
          end: match.end,
          raw: match.group(0) ?? '',
        );
      }
    }

    for (final match in segmentRegex.allMatches(text)) {
      if (position >= match.start && position <= match.end) {
        final marker = (match.group(1) ?? '').trim().toLowerCase();

        return TemplateEditorTokenMatch(
          kind: marker == '/segment'
              ? TemplateEditorTokenKind.segmentEnd
              : TemplateEditorTokenKind.segmentStart,
          start: match.start,
          end: match.end,
          raw: match.group(0) ?? '',
        );
      }
    }

    return null;
  }

  static TemplateEditorFieldSpec parseFieldToken(String token) {
    final match = fieldRegex.firstMatch(token);

    if (match == null) {
      return const TemplateEditorFieldSpec(label: 'Nazwa pola');
    }

    final label = stripQuotes(match.group(1)?.trim() ?? 'Nazwa pola');
    final config = match.group(2)?.trim() ?? '';

    var type = TemplateEditorFieldType.text;
    var required = false;
    int? maxLength;
    num? min;
    num? max;
    String? defaultPrefix;
    String? defaultValue;
    String? helpText;
    String? key;
    var options = <TemplateEditorFieldOption>[];

    for (final part in splitTopLevel(config)) {
      final clean = part.trim();
      final lower = clean.toLowerCase();

      if (lower == 'required' || lower == 'req') {
        required = true;
        continue;
      }

      final parsedType = parseType(lower);
      if (parsedType != null) {
        type = parsedType;
        continue;
      }

      final separatorIndex = clean.indexOf(':');
      if (separatorIndex == -1) continue;

      final fieldName = clean.substring(0, separatorIndex).trim().toLowerCase();
      final value = clean.substring(separatorIndex + 1).trim();

      switch (fieldName) {
        case 'key':
        case 'id':
        case 'field':
          key = stripQuotes(value);
          break;

        case 'len':
        case 'maxlen':
        case 'maxlength':
        case 'max_length':
          maxLength = int.tryParse(stripQuotes(value));
          break;

        case 'min':
          min = num.tryParse(stripQuotes(value).replaceAll(',', '.'));
          break;

        case 'max':
          max = num.tryParse(stripQuotes(value).replaceAll(',', '.'));
          break;

        case 'prefix':
          defaultPrefix = stripQuotes(value);
          break;

        case 'default':
        case 'default_value':
        case 'value':
          defaultValue = stripQuotes(value);
          break;

        case 'help':
        case 'help_text':
        case 'hint':
          helpText = stripQuotes(value);
          break;

        case 'type':
          final typedValue = parseType(stripQuotes(value).toLowerCase());
          if (typedValue != null) {
            type = typedValue;
          }
          break;

        case 'opt':
        case 'opts':
        case 'option':
        case 'options':
        case 'select':
        case 'dropdown':
          options = parseOptions(value);
          if (options.isNotEmpty) {
            type = TemplateEditorFieldType.dropdown;
          }
          break;
      }
    }

    return TemplateEditorFieldSpec(
      label: label,
      key: key,
      type: type,
      required: required,
      maxLength: maxLength,
      min: min,
      max: max,
      defaultPrefix: defaultPrefix,
      defaultValue: defaultValue,
      helpText: helpText,
      options: options,
    );
  }

  static TemplateEditorSegmentSpec parseSegmentStartToken(String token) {
    final match = segmentRegex.firstMatch(token);

    if (match == null) {
      return const TemplateEditorSegmentSpec(label: 'Dane dodatkowe');
    }

    final config = match.group(2)?.trim() ?? '';

    var label = 'Dane dodatkowe';
    var skipable = false;
    var labelSet = false;

    for (final part in splitTopLevel(config)) {
      final clean = part.trim();
      final lower = clean.toLowerCase();

      if (lower == 'skipable' ||
          lower == 'skippable' ||
          lower == 'optional' ||
          lower == 'skip') {
        skipable = true;
        continue;
      }

      final separatorIndex = clean.indexOf(':');

      if (separatorIndex != -1) {
        final key = clean.substring(0, separatorIndex).trim().toLowerCase();
        final value = clean.substring(separatorIndex + 1).trim();

        if (key == 'label' || key == 'title' || key == 'name') {
          label = stripQuotes(value);
          labelSet = true;
          continue;
        }

        if (key == 'skipable' || key == 'skippable' || key == 'optional') {
          skipable = parseBool(value);
          continue;
        }
      }

      if (!labelSet && clean.isNotEmpty) {
        label = stripQuotes(clean);
        labelSet = true;
      }
    }

    return TemplateEditorSegmentSpec(
      label: label.trim().isEmpty ? 'Dane dodatkowe' : label.trim(),
      skipable: skipable,
    );
  }

  static String formatField(TemplateEditorFieldSpec spec) {
    final config = <String>[];

    if (spec.key != null && spec.key!.trim().isNotEmpty) {
      config.add('key:${slugify(spec.key!.trim())}');
    }

    switch (spec.type) {
      case TemplateEditorFieldType.text:
        if (spec.maxLength != null) config.add('len:${spec.maxLength}');
        break;
      case TemplateEditorFieldType.textarea:
        config.add('textarea');
        if (spec.maxLength != null) config.add('len:${spec.maxLength}');
        break;
      case TemplateEditorFieldType.email:
        config.add('email');
        break;
      case TemplateEditorFieldType.phone:
        config.add('phone');
        if (spec.defaultPrefix != null &&
            spec.defaultPrefix!.trim().isNotEmpty) {
          config.add('prefix:${spec.defaultPrefix!.trim()}');
        }
        if (spec.maxLength != null) config.add('len:${spec.maxLength}');
        break;
      case TemplateEditorFieldType.number:
        config.add('number');
        if (spec.min != null) config.add('min:${spec.min}');
        if (spec.max != null) config.add('max:${spec.max}');
        break;
      case TemplateEditorFieldType.money:
        config.add('money');
        if (spec.min != null) config.add('min:${spec.min}');
        if (spec.max != null) config.add('max:${spec.max}');
        break;
      case TemplateEditorFieldType.date:
        config.add('date');
        break;
      case TemplateEditorFieldType.datetime:
        config.add('datetime');
        break;
      case TemplateEditorFieldType.dropdown:
        config.add(_formatOptions(spec.options));
        break;
      case TemplateEditorFieldType.multiselect:
        config.add('multiselect');
        config.add(_formatOptions(spec.options));
        break;
      case TemplateEditorFieldType.checkbox:
        config.add('checkbox');
        break;
      case TemplateEditorFieldType.boolean:
        config.add('boolean');
        break;
    }

    if (spec.required) config.add('required');

    if (spec.defaultValue != null && spec.defaultValue!.trim().isNotEmpty) {
      config.add('default:${spec.defaultValue!.trim()}');
    }

    if (spec.helpText != null && spec.helpText!.trim().isNotEmpty) {
      config.add('help:${spec.helpText!.trim()}');
    }

    final label = spec.label.trim().isEmpty ? 'Nazwa pola' : spec.label.trim();

    if (config.isEmpty) {
      return '{...{$label}...}';
    }

    return '{...{$label}:[${config.join(', ')}]...}';
  }

  static String _formatOptions(List<TemplateEditorFieldOption> options) {
    return 'opt:{${options.map((option) {
      return '${option.value}:${option.label}';
    }).join(', ')}}';
  }

  static String formatSegmentStart(TemplateEditorSegmentSpec spec) {
    final config = <String>[];

    final label =
        spec.label.trim().isEmpty ? 'Dane dodatkowe' : spec.label.trim();

    config.add(label);

    if (spec.skipable) {
      config.add('skipable');
    }

    return '{...[segment:${config.join(', ')}]...}';
  }

  static String formatSegmentEnd() {
    return '{...[/segment]...}';
  }

  static TemplateEditorFieldType? parseType(String value) {
    final normalized = stripQuotes(value).toLowerCase().trim();

    switch (normalized) {
      case 'text':
      case 'char':
      case 'string':
        return TemplateEditorFieldType.text;
      case 'textarea':
      case 'longtext':
      case 'long_text':
        return TemplateEditorFieldType.textarea;
      case 'email':
      case 'mail':
        return TemplateEditorFieldType.email;
      case 'phone':
      case 'tel':
      case 'telephone':
        return TemplateEditorFieldType.phone;
      case 'number':
      case 'num':
      case 'int':
      case 'integer':
      case 'decimal':
      case 'float':
        return TemplateEditorFieldType.number;
      case 'money':
      case 'currency':
      case 'price':
        return TemplateEditorFieldType.money;
      case 'date':
        return TemplateEditorFieldType.date;
      case 'datetime':
      case 'date_time':
        return TemplateEditorFieldType.datetime;
      case 'select':
      case 'dropdown':
      case 'option':
      case 'options':
      case 'opt':
        return TemplateEditorFieldType.dropdown;
      case 'multiselect':
      case 'multi_select':
        return TemplateEditorFieldType.multiselect;
      case 'checkbox':
        return TemplateEditorFieldType.checkbox;
      case 'boolean':
      case 'bool':
        return TemplateEditorFieldType.boolean;
    }

    return null;
  }

  static String typeLabel(TemplateEditorFieldType type) {
    switch (type) {
      case TemplateEditorFieldType.text:
        return 'Tekst';
      case TemplateEditorFieldType.textarea:
        return 'Długi tekst';
      case TemplateEditorFieldType.email:
        return 'E-mail';
      case TemplateEditorFieldType.phone:
        return 'Telefon';
      case TemplateEditorFieldType.number:
        return 'Liczba';
      case TemplateEditorFieldType.money:
        return 'Kwota';
      case TemplateEditorFieldType.date:
        return 'Data';
      case TemplateEditorFieldType.datetime:
        return 'Data i godzina';
      case TemplateEditorFieldType.dropdown:
        return 'Dropdown';
      case TemplateEditorFieldType.multiselect:
        return 'Multi-select';
      case TemplateEditorFieldType.checkbox:
        return 'Checkbox';
      case TemplateEditorFieldType.boolean:
        return 'Tak / Nie';
    }
  }

  static List<TemplateEditorFieldOption> parseOptions(String raw) {
    var value = raw.trim();

    if (value.startsWith('{') && value.endsWith('}')) {
      value = value.substring(1, value.length - 1);
    }

    final parts = splitTopLevel(value);
    final options = <TemplateEditorFieldOption>[];

    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;

      final separatorIndex = part.indexOf(':');

      if (separatorIndex == -1) {
        final optionValue = stripQuotes(part);

        options.add(
          TemplateEditorFieldOption(
            value: slugify(optionValue),
            label: optionValue,
          ),
        );
      } else {
        final optionValue = stripQuotes(
          part.substring(0, separatorIndex).trim(),
        );
        final optionLabel = stripQuotes(
          part.substring(separatorIndex + 1).trim(),
        );

        options.add(
          TemplateEditorFieldOption(
            value: optionValue,
            label: optionLabel,
          ),
        );
      }
    }

    return options;
  }

  static List<TemplateEditorFieldOption> parseEditableOptions(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final options = <TemplateEditorFieldOption>[];

    for (final line in lines) {
      final separatorIndex = line.indexOf(':');

      if (separatorIndex == -1) {
        options.add(
          TemplateEditorFieldOption(
            value: slugify(line),
            label: line,
          ),
        );
      } else {
        final value = stripQuotes(line.substring(0, separatorIndex).trim());
        final label = stripQuotes(line.substring(separatorIndex + 1).trim());

        options.add(
          TemplateEditorFieldOption(
            value: value,
            label: label,
          ),
        );
      }
    }

    return options;
  }

  static String optionsToEditableText(List<TemplateEditorFieldOption> options) {
    return options.map((option) => '${option.value}:${option.label}').join('\n');
  }

  static List<String> splitTopLevel(String input) {
    final result = <String>[];
    final buffer = StringBuffer();

    var curly = 0;
    var square = 0;
    var round = 0;
    String? quote;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (quote != null) {
        buffer.write(char);

        if (char == quote && (i == 0 || input[i - 1] != '\\')) {
          quote = null;
        }

        continue;
      }

      if (char == '"' || char == "'") {
        quote = char;
        buffer.write(char);
        continue;
      }

      if (char == '{') curly++;
      if (char == '}') curly--;
      if (char == '[') square++;
      if (char == ']') square--;
      if (char == '(') round++;
      if (char == ')') round--;

      if (char == ',' && curly == 0 && square == 0 && round == 0) {
        result.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    final rest = buffer.toString().trim();

    if (rest.isNotEmpty) {
      result.add(rest);
    }

    return result;
  }

  static String stripQuotes(String value) {
    var result = value.trim();

    if (result.length >= 2) {
      final first = result[0];
      final last = result[result.length - 1];

      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        result = result.substring(1, result.length - 1);
      }
    }

    return result.trim();
  }

  static bool parseBool(String value) {
    final normalized = stripQuotes(value).toLowerCase().trim();

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'tak';
  }

  static String slugify(String value) {
    var text = value.toLowerCase().trim();

    const replacements = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ż': 'z',
      'ź': 'z',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    text = text.replaceAll(RegExp(r'^_+|_+$'), '');

    if (text.isEmpty) return 'option';

    if (!RegExp(r'^[a-z]').hasMatch(text)) {
      text = 'option_$text';
    }

    return text;
  }
}