import SwiftUI
import AVFoundation

// Telão para iPad (e iPhone): o site devlumo.com.br/telao em tela cheia, com o que o
// navegador sozinho não consegue: bloqueio das janelas de anúncio dos players, vídeo em
// tela cheia/horizontal e som mesmo com o iPad no modo silencioso.
@main
struct TelaoApp: App {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var carregou = false
    @State private var semRede = false
    @State private var recarregar = 0

    var body: some View {
        ZStack {
            Color(red: 0.078, green: 0.078, blue: 0.078).ignoresSafeArea()

            TelaoWebView(carregou: $carregou, semRede: $semRede, recarregar: recarregar)
                .ignoresSafeArea()
                .opacity(carregou ? 1 : 0)

            if !carregou && !semRede {
                Abertura()
                    .transition(.opacity)
            }

            if semRede {
                SemConexao {
                    semRede = false
                    recarregar += 1
                }
            }
        }
        .animation(.easeOut(duration: 0.35), value: carregou)
    }
}

/// Tela de abertura: a marca enquanto a página carrega.
struct Abertura: View {
    @State private var pulsar = false

    var body: some View {
        VStack(spacing: 22) {
            Text("TELÃO")
                .font(.system(size: 60, weight: .heavy, design: .default))
                .tracking(-1)
                .foregroundStyle(Color(red: 0.898, green: 0.035, blue: 0.078))
                .shadow(color: Color(red: 0.898, green: 0.035, blue: 0.078).opacity(0.45), radius: pulsar ? 26 : 10)
            ProgressView()
                .controlSize(.regular)
                .tint(.white.opacity(0.6))
                .padding(14)
                .background(.ultraThinMaterial, in: Circle())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulsar = true }
        }
    }
}

struct SemConexao: View {
    var tentar: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Sem conexão")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Confira a internet do iPad e tente de novo.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
            Button("Tentar de novo", action: tentar)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.898, green: 0.035, blue: 0.078))
                .padding(.top, 6)
        }
        .padding(32)
    }
}
