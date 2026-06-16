
using Javelin.API.Configurations.Exstentions;
using Javelin.API.Configurations.Models;

namespace Javelin.API
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();


            AppConfig appConfig = new();
            builder.Configuration.GetSection("AppConfig").Bind(appConfig);
            builder.Services.AddSingleton(appConfig);

            builder.Services.ConfigureKafkaServices();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
