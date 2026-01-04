using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StickBy.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddApkRelease : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ApkReleases",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Version = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    FileName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    FileData = table.Column<byte[]>(type: "bytea", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    ReleaseNotes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UploadedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsLatest = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ApkReleases", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ApkReleases_AspNetUsers_UploadedByUserId",
                        column: x => x.UploadedByUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ApkReleases_IsLatest",
                table: "ApkReleases",
                column: "IsLatest");

            migrationBuilder.CreateIndex(
                name: "IX_ApkReleases_UploadedAt",
                table: "ApkReleases",
                column: "UploadedAt");

            migrationBuilder.CreateIndex(
                name: "IX_ApkReleases_UploadedByUserId",
                table: "ApkReleases",
                column: "UploadedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_ApkReleases_Version",
                table: "ApkReleases",
                column: "Version");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ApkReleases");
        }
    }
}
