APP_DIR := .
TMP_DIR := /tmp/jibas_install
JIBAS_VERSION := 32.0
JIBAS_SRC_URL := https://jibas.id/res/jibas/jibas.src-32.0.7z
JIBAS_ARCHIVE_NAME := jibas.src-${JIBAS_VERSION}.7z
JIBAS_EXTRACTED_DIR_NAME := jibas-${JIBAS_VERSION}

# Variabel koneksi database (sebaiknya diambil dari .env atau konfigurasi aplikasi)
# Untuk kemudahan contoh, kita bisa definisikan di sini atau membacanya dari env.
# Namun, skrip PHP untuk setup DB sebaiknya membaca dari file konfigurasi aplikasi.
DB_HOST := 127.0.0.1
DB_PORT := $(shell grep DB_PORT .env | cut -d '=' -f2) # Baca dari .env
DB_NAME := $(shell grep DB_DATABASE .env | cut -d '=' -f2)
DB_USER := $(shell grep DB_USERNAME .env | cut -d '=' -f2)
DB_PASS := $(shell grep DB_PASSWORD .env | cut -d '=' -f2)
DB_ROOT_PASS := $(shell grep DB_ROOT_PASSWORD .env | cut -d '=' -f2)

# Target default
all: install

# Target untuk membersihkan hasil download dan instalasi sementara
clean:
	@echo "Membersihkan direktori sementara..."
	@rm -rf $(TMP_DIR)
	@echo "Selesai."

# Target untuk mengunduh dan mengekstrak source code JIBAS
download-extract: clean
	@echo "Membuat direktori sementara: $(TMP_DIR)"
	@mkdir -p $(TMP_DIR)
	@echo "Mengunduh JIBAS versi $(JIBAS_VERSION) dari $(JIBAS_SRC_URL)..."
	@wget -O $(TMP_DIR)/$(JIBAS_ARCHIVE_NAME) $(JIBAS_SRC_URL)
	@echo "Mengekstrak $(JIBAS_ARCHIVE_NAME) ke $(TMP_DIR)..."
	@7z x -y -o$(TMP_DIR) $(TMP_DIR)/$(JIBAS_ARCHIVE_NAME)
	@echo "Ekstraksi selesai."

# Target untuk menyalin file aplikasi ke direktori tujuan
copy-app: download-extract
	@echo "Menyalin file aplikasi dari $(TMP_DIR)/$(JIBAS_EXTRACTED_DIR_NAME)/ ke $(APP_DIR)/..."
	# Pastikan JIBAS_EXTRACTED_DIR_NAME sesuai dengan nama folder setelah 7z mengekstrak
	@cp -r $(TMP_DIR)/$(JIBAS_EXTRACTED_DIR_NAME)/* $(APP_DIR)/
	@echo "Penyalinan file aplikasi selesai."

# Target untuk mengatur hak akses
set-permissions:
	@echo "Mengatur hak akses untuk direktori dan file di $(APP_DIR)..."
	@find $(APP_DIR) -type d -exec chmod 755 {} \;
	@find $(APP_DIR) -type f -exec chmod 644 {} \;
	# Jika ada direktori tertentu yang butuh hak tulis oleh web server (misal: uploads, cache)
	# @chmod -R 775 $(APP_DIR)/writable_directory
	# @chown -R $(shell whoami):www-data $(APP_DIR) # Sesuaikan user dan group web server
	@echo "Pengaturan hak akses selesai."

# Target untuk instalasi dependensi PHP menggunakan Composer (jika JIBAS menggunakannya)
composer-install:
	@if [ -f "$(APP_DIR)/composer.json" ]; then \
		echo "Menjalankan composer install di $(APP_DIR)..."; \
		composer install --no-dev --optimize-autoloader -d $(APP_DIR); \
		echo "Composer install selesai."; \
	else \
		echo "composer.json tidak ditemukan, melewati composer install."; \
	fi

# Target untuk setup database (contoh, mungkin perlu disesuaikan)
# Ini mengasumsikan Anda memiliki skrip SQL atau PHP untuk setup database.
setup-database:
	@echo "Memulai setup database..."
	# Contoh 1: Jika Anda memiliki skrip SQL untuk diimpor
	# Pastikan mysql client terinstal di host dan DB_PORT, DB_USER, dll, sudah benar.
	# @echo "Mengimpor skema database dari skema.sql..."
	# @mysql -h $(DB_HOST) -P $(DB_PORT) -u $(DB_USER) -p$(DB_PASS) $(DB_NAME) < $(APP_DIR)/skema_database.sql

	# Contoh 2: Jika Anda memiliki skrip PHP untuk setup database
	@if [ -f "$(APP_DIR)/scripts/install_db.php" ]; then \
		echo "Menjalankan skrip PHP untuk setup database: scripts/install_db.php..."; \
		php $(APP_DIR)/scripts/install_db.php; \
		echo "Skrip setup database selesai."; \
	else \
		echo "Skrip scripts/install_db.php tidak ditemukan. Setup database mungkin perlu dilakukan manual atau dengan cara lain."; \
	fi
	@echo "Setup database selesai."

# Target utama untuk instalasi
install: copy-app set-permissions composer-install setup-database
	@echo "Instalasi JIBAS selesai."
	@echo "Pastikan Nginx dan PHP-FPM di host Anda sudah dikonfigurasi dengan benar."
	@echo "Akses aplikasi melalui browser Anda."

.PHONY: all clean download-extract copy-app set-permissions composer-install setup-database install
