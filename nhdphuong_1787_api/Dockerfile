# Stage 1: Build & Publish
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project file and restore
COPY nhdphuong_1787_api.csproj ./
RUN dotnet restore nhdphuong_1787_api.csproj

# Copy source code and publish release
COPY . ./
RUN dotnet publish nhdphuong_1787_api.csproj -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Expose default HTTP port
EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080

ENTRYPOINT ["dotnet", "nhdphuong_1787_api.dll"]
