
using Asp.Versioning;
using Javelin.API.Configurations.Exstentions;
using Javelin.API.Configurations.Models;
using Scalar.AspNetCore;
using Serilog;

namespace Javelin.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            // Serilog
            builder.Host.UseSerilog((hostingContext, loggerConfiguration) =>
                loggerConfiguration.ReadFrom.Configuration(hostingContext.Configuration));

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddApiVersioning(opt =>
            {
                opt.ReportApiVersions = true;
                opt.AssumeDefaultVersionWhenUnspecified = true;
                opt.DefaultApiVersion = new ApiVersion(1, 0);
            });
            builder.Services.AddOpenApi();

            AppConfig appConfig = new();
            builder.Configuration.GetSection("AppConfig").Bind(appConfig);
            builder.Services.AddSingleton(appConfig);

            //Kafka Service
            builder.Services.ConfigureKafkaServices();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
                app.MapScalarApiReference();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
