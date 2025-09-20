import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:pointo/gen_l10n/app_localizations.dart';

class AboutDeveloperPage extends StatelessWidget {
  const AboutDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем текущую тему
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.about_developer),
        backgroundColor: colorScheme.primary, // Используем primary из темы
        foregroundColor: colorScheme.onPrimary, // Используем onPrimary из темы
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/dmitry.jpg',
                  width: 180,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 1000.ms),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.universityShort,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ).animate().fadeIn(duration: 1000.ms, delay: 200.ms),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor, // Используем cardColor из темы
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context)!.universityFull,
                  style: theme.textTheme.bodyLarge,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
            ),

            const SizedBox(height: 30),

            Text(
              AppLocalizations.of(context)!.hobbyTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  VideoHobbyCard(
                    videoAsset: 'assets/video/skating.mp4',
                    coverImage: 'assets/icon/skating.jpg',
                    title: AppLocalizations.of(context)!.hobbyFigureSkating,
                  ),
                  VideoHobbyCard(
                    videoAsset: 'assets/video/snowboard.mp4',
                    coverImage: 'assets/icon/snowboard.jpg',
                    title: AppLocalizations.of(context)!.hobbySnowboard,
                  ),
                  VideoHobbyCard(
                    videoAsset: 'assets/video/wakeboard.mp4',
                    coverImage: 'assets/icon/wakeboard.jpg',
                    title: AppLocalizations.of(context)!.hobbyWakeboard,
                  ),
                  VideoHobbyCard(
                    videoAsset: 'assets/video/football.mp4',
                    coverImage: 'assets/icon/football.jpg',
                    title: AppLocalizations.of(context)!.hobbyFootball,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Цитата
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    AppLocalizations.of(context)!.quoteTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer, // Используем primaryContainer из темы
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.quoteText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Контакты
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.contactsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(context, Icons.email, 'dmitry.kamkov@gmail.com'),
                  _buildContactRow(context, Icons.phone, '+7-999-563-35-90'),
                  _buildContactRow(context, Icons.telegram, '@dkamkov'),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor, // Используем scaffoldBackgroundColor из темы
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    // Получение цветовой схемы из темы
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary), // Используем primary из темы
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoHobbyCard extends StatefulWidget {
  final String videoAsset;
  final String coverImage;
  final String title;

  const VideoHobbyCard({
    Key? key,
    required this.videoAsset,
    required this.coverImage,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoHobbyCard> createState() => _VideoHobbyCardState();
}

class _VideoHobbyCardState extends State<VideoHobbyCard> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(widget.videoAsset)
      ..setVolume(0.0) // Устанавливаем громкость на 0
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          showControls: false,
        );

        setState(() {});
      });

    _videoController.addListener(() {
      if (_videoController.value.position >= _videoController.value.duration &&
          _isPlaying) {
        setState(() {
          _isPlaying = false;
          _videoController.seekTo(Duration.zero);
        });
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _startVideo() {
    if (_chewieController != null) {
      setState(() {
        _isPlaying = true;
        _videoController.seekTo(Duration.zero);
        _videoController.play();
      });
    } else {
      debugPrint("⚠ ChewieController не инициализирован");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем тему
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: !_isPlaying ? _startVideo : null,
      child: Container(
        width: 160,
        height: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary, width: 1.5), // Используем primary из темы
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.bottomCenter,
            children: [
              // ВИДЕО
              if (_chewieController != null && _isPlaying)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                ),

              // ФОТО + ТЕКСТ
              AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.coverImage,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}