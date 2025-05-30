import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class NotesWidget extends StatefulWidget {
  final String initialNote;

  const NotesWidget({Key? key, required this.initialNote}) : super(key: key);

  @override
  State<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  late TextEditingController _controller;
  String _savedNote = "";

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _savedNote = widget.initialNote;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    setState(() {
      _savedNote = _controller.text;
    });
    // Add any additional logic for saving the note, such as storing it in a database or shared preferences.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.background,
                child: const Icon(Icons.note, color: AppColors.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                "Notas",
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Escribe tus notas aquí...",
              hintStyle: TextStyle(color: AppColors.textMedium.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                "Guardar",
                style: TextStyle(color: AppColors.background),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_savedNote.isNotEmpty)
            Text(
              "Nota guardada: $_savedNote",
              style: const TextStyle(color: AppColors.textMedium, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
