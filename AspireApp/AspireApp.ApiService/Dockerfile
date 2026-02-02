FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["AspireApp/AspireApp.ApiService/AspireApp.ApiService.csproj", "AspireApp/AspireApp.ApiService/"]
COPY ["AspireApp/AspireApp.ServiceDefaults/AspireApp.ServiceDefaults.csproj", "AspireApp/AspireApp.ServiceDefaults/"]
RUN dotnet restore "AspireApp/AspireApp.ApiService/AspireApp.ApiService.csproj"
COPY ["AspireApp/AspireApp.ApiService/", "AspireApp/AspireApp.ApiService/"]
COPY ["AspireApp/AspireApp.ServiceDefaults/", "AspireApp/AspireApp.ServiceDefaults/"]
RUN dotnet build "AspireApp/AspireApp.ApiService/AspireApp.ApiService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AspireApp/AspireApp.ApiService/AspireApp.ApiService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["dotnet", "AspireApp.ApiService.dll"]
