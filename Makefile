
APP_DIR := ./app
TMP_DIR := /tmp/jibas_install
JIBAS_SRC_URL := https://jibas.id/res/jibas/jibas.src-32.0.7z
JIBAS_ARCHIVE_NAME := jibas.src-32.0.7z
JIBAS_DIR := jibas-32.0
SQL_FILE_NAME := jibas_db.sql
# Path lengkap ke file SQL
SQL_FULL_PATH := $(APP_DIR)/$(SQL_FILE_NAME)
CONFIG_FILE := $(APP_DIR)/jibas/include/database.config.php

# Variabel koneksi database (sebaiknya diambil dari .env atau konfigurasi aplikasi)
# Menggunakan $(strip ...) untuk membersihkan spasi ekstra dari nilai .env
DB_HOST := 127.0.0.1
DB_PORT := $(strip $(shell grep DB_PORT .env | cut -d '=' -f2))
DB_NAME := $(strip $(shell grep DB_DATABASE .env | cut -d '=' -f2))
DB_USER := $(strip $(shell grep DB_USERNAME .env | cut -d '=' -f2))
DB_ROOT_PASS := $(strip $(shell grep DB_ROOT_PASSWORD .env | cut -d '=' -f2))

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
	@wget --no-check-certificate -O $(TMP_DIR)/$(JIBAS_ARCHIVE_NAME) $(JIBAS_SRC_URL)
	@echo "Mengekstrak $(JIBAS_ARCHIVE_NAME) ke $(TMP_DIR)..."
	@7z x -y -o$(TMP_DIR) $(TMP_DIR)
	@echo "Ekstraksi selesai."

# Target untuk menyalin file aplikasi ke direktori tujuan
copy-app: download-extract
	@echo "Menyalin file aplikasi dari $(TMP_DIR)/$(JIBAS_DIR)/ ke $(APP_DIR)/..."
	# Pastikan JIBAS_EXTRACTED_DIR_NAME sesuai dengan nama folder setelah 7z mengekstrak
	@cp -r $(TMP_DIR)/$(JIBAS_DIR)/* $(APP_DIR)/
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


# Target untuk setup database
setup-database:
	@echo "Memulai setup database..."
	@if [ ! -f "$(SQL_FULL_PATH)" ]; then \
		echo "ERROR: File SQL '$(SQL_FULL_PATH)' tidak ditemukan!"; \
		exit 1; \
	fi
	# Mengimpor skema database menggunakan user root
	@echo "Mengimpor skema database dari $(SQL_FULL_PATH) menggunakan user root..."
	@mysql -h "$(DB_HOST)" -P "$(DB_PORT)" -u root -p"$(DB_ROOT_PASS)" < "$(SQL_FULL_PATH)"
	@echo "Setup database selesai."
	

# Target untuk membuat/memperbarui file konfigurasi database aplikasi
config:
	echo "<? \$$db_host='localhost:$(DB_PORT)';\$$db_user='root';\$$db_pass='$(DB_ROOT_PASS)';\$$db_name='jbsakad'; ?>" > $(CONFIG_FILE)
	@echo "File konfigurasi $(CONFIG_FILE) telah dibuat/diperbarui."


# Target utama untuk instalasi
install: copy-app set-permissions composer-install config setup-database
	@echo "Instalasi JIBAS selesai."
	@echo "Pastikan Nginx dan PHP-FPM di host Anda sudah dikonfigurasi dengan benar."
	@echo "Akses aplikasi melalui browser Anda."

.PHONY: all clean download-extract copy-app set-permissions composer-install config setup-database install 
